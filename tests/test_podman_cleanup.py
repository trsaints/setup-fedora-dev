"""Read-only regression tests for the Podman replacement block.

Only parse tasks and evaluate templates/conditions; never run Ansible modules.
"""

import os
from pathlib import Path
import unittest

import yaml

# Ansible's Display otherwise uses the repository's logs/ansible.log.
os.environ["ANSIBLE_LOG_PATH"] = os.devnull

from ansible.parsing.dataloader import DataLoader
from ansible.playbook.block import Block
from ansible.plugins.loader import init_plugin_loader
from ansible.template import Templar, trust_as_template


ROOT = Path(__file__).resolve().parents[1]
BLOCK_NAME = "Replace Podman stack before Docker CE install"
EXPECTED_PACKAGES = {
    "podman",
    "podman-docker",
    "buildah",
    "skopeo",
    "containers-common",
    "containers-common-extra",
    "toolbox",
}
EXPECTED_ACTIONS = [
    "package_facts",
    "set_fact",
    "command",
    "systemd",
    "dnf",
    "debug",
    "file",
]


class PodmanCleanupTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        with (ROOT / "playbook.yml").open(encoding="utf-8") as stream:
            cls.play = yaml.safe_load(stream)[0]
        with (ROOT / "group_vars/all.yml").open(encoding="utf-8") as stream:
            cls.variables = yaml.safe_load(stream)
        matches = [
            task for task in cls.play["tasks"] if task.get("name") == BLOCK_NAME
        ]
        if len(matches) != 1:
            raise AssertionError("Expected exactly one Podman replacement block")
        cls.raw_block = matches[0]

        # Use Ansible's parser for inherited when/tags/error handling, and its
        # Templar (Jinja + the real builtin intersect filter) for evaluation.
        # Trust only the YAML read from this repository, as Ansible does for
        # playbook sources; synthetic inventory values remain ordinary data.
        init_plugin_loader()
        cls.loader = DataLoader()
        data = cls.loader.load(trust_as_template(yaml.safe_dump(cls.raw_block)))
        cls.block = Block.load(data, loader=cls.loader)

    def task(self, action):
        matches = [
            task
            for task in self.block.block
            if task.action == "ansible.builtin." + action
        ]
        self.assertEqual(len(matches), 1, action)
        return matches[0]

    def context(self, packages, load_state=None):
        facts = {"packages": {name: [{"name": name}] for name in packages}}
        context = {
            "install_docker_ce": True,
            "replace_podman_with_docker": True,
            "podman_packages": self.variables["podman_packages"],
            "ansible_facts": facts,
        }
        if load_state is not None:
            context["podman_socket_load_state"] = {"stdout": load_state, "rc": 0}
        return context

    def render(self, value, context):
        return Templar(loader=self.loader, variables=context).template(value)

    def select_packages(self, context):
        expression = self.task("set_fact").args["installed_podman_packages"]
        selected = self.render(expression, context)
        self.assertIsInstance(selected, list)
        context["installed_podman_packages"] = selected
        return selected

    def enabled(self, action, context):
        templar = Templar(loader=self.loader, variables=context)
        # task.when includes the enclosing block's guard, prepended by Ansible.
        # all() preserves Ansible's short-circuiting of successive conditions.
        return all(
            templar.evaluate_conditional(condition)
            for condition in self.task(action).when
        )

    def test_package_allowlist(self):
        packages = self.variables["podman_packages"]
        self.assertEqual(set(packages), EXPECTED_PACKAGES)
        self.assertEqual(len(packages), len(EXPECTED_PACKAGES))

    def test_task_order_tag_and_placement(self):
        self.assertEqual(
            [task.action for task in self.block.block],
            ["ansible.builtin." + action for action in EXPECTED_ACTIONS],
        )
        for task in self.block.block:
            with self.subTest(task=task.name):
                self.assertIn("podman_cleanup", task.tags)
        tasks = self.play["tasks"]
        docker_install = next(
            task for task in tasks if task.get("name") == "Install Docker CE packages"
        )
        self.assertLess(tasks.index(self.raw_block), tasks.index(docker_install))

    def test_package_facts_uses_rpm(self):
        self.assertEqual(self.task("package_facts").args, {"manager": "rpm"})
        self.assertTrue(self.enabled("package_facts", self.context([])))
        self.assertTrue(self.enabled("set_fact", self.context([])))

    def test_partial_inventory(self):
        context = self.context(
            ["toolbox", "bash", "podman", "containers-common-extra", "docker-ce"]
        )
        expected = ["containers-common-extra", "podman", "toolbox"]
        self.assertEqual(self.select_packages(context), expected)
        self.assertEqual(self.render(self.task("dnf").args["name"], context), expected)
        for action in ("command", "dnf", "debug"):
            with self.subTest(action=action):
                self.assertTrue(self.enabled(action, context))

    def test_all_packages_absent(self):
        for inventory in ([], ["bash", "docker-ce", "containerd.io"]):
            with self.subTest(inventory=inventory):
                context = self.context(inventory)  # Neither query nor removal result.
                self.assertEqual(self.select_packages(context), [])
                self.assertNotIn("podman_socket_load_state", context)
                for action in ("command", "systemd", "dnf", "debug"):
                    self.assertFalse(self.enabled(action, context), action)
                self.assertTrue(self.enabled("file", context))

    def test_all_packages_present_are_sorted(self):
        context = self.context(list(reversed(sorted(EXPECTED_PACKAGES))) + ["bash"])
        expected = sorted(EXPECTED_PACKAGES)
        self.assertEqual(self.select_packages(context), expected)
        self.assertEqual(self.render(self.task("dnf").args["name"], context), expected)

    def test_exact_names_only(self):
        lookalikes = [
            "podman-remote",
            "podman-tests",
            "podman-docker-extra",
            "Podman",
            "containers-common-extras",
            "toolbox-extra",
            "podman-5.0-1.fc44.x86_64",
        ]
        context = self.context(lookalikes)
        self.assertEqual(self.select_packages(context), [])
        context["ansible_facts"]["packages"]["podman"] = [{"name": "podman"}]
        self.assertEqual(self.select_packages(context), ["podman"])

    def test_duplicate_configuration_and_multiple_rpm_records(self):
        context = self.context(["podman", "toolbox"])
        context["podman_packages"] = ["toolbox", "podman", "toolbox", "podman"]
        context["ansible_facts"]["packages"]["podman"] = [
            {"name": "podman", "arch": "x86_64"},
            {"name": "podman", "arch": "i686"},
        ]
        self.assertEqual(self.select_packages(context), ["podman", "toolbox"])

    def test_repeat_with_inventory_after_removal(self):
        context = self.context(
            sorted(EXPECTED_PACKAGES) + ["bash", "docker-ce"], "loaded\n"
        )
        self.assertEqual(self.select_packages(context), sorted(EXPECTED_PACKAGES))
        self.assertTrue(self.enabled("command", context))
        self.assertTrue(self.enabled("systemd", context))
        self.assertTrue(self.enabled("dnf", context))
        # Supply a synthetic post-removal snapshot, not a real DNF transaction.
        context["ansible_facts"]["packages"] = {"bash": [], "docker-ce": []}
        context["podman_removal"] = {"results": ["stale first-run result"]}
        self.assertEqual(self.select_packages(context), [])
        for action in ("command", "systemd", "dnf", "debug"):
            self.assertFalse(self.enabled(action, context), action)
        self.assertTrue(self.enabled("file", context))

    def test_disabled_flags_skip_every_task_without_facts(self):
        for docker, replace in ((False, True), (True, False), (False, False)):
            with self.subTest(install_docker_ce=docker, replace=replace):
                context = {
                    "install_docker_ce": docker,
                    "replace_podman_with_docker": replace,
                }
                for action in EXPECTED_ACTIONS:
                    self.assertFalse(self.enabled(action, context), action)

    def test_socket_query_is_read_only_and_available_in_check_mode(self):
        task = self.task("command")
        self.assertEqual(task.name, "Check Podman socket unit before replacement")
        self.assertEqual(
            task.args,
            {
                "argv": [
                    "systemctl",
                    "show",
                    "--property=LoadState",
                    "--value",
                    "podman.socket",
                ]
            },
        )
        self.assertEqual(task.register, "podman_socket_load_state")
        self.assertIs(task.check_mode, False)
        self.assertFalse(task.become)
        self.assertFalse(task.loop)
        self.assertEqual(task.changed_when, [False])
        for check_mode in (False, True):
            with self.subTest(check_mode=check_mode):
                context = self.context(["podman"])
                context["ansible_check_mode"] = check_mode
                self.select_packages(context)
                self.assertTrue(self.enabled("command", context))
                templar = Templar(loader=self.loader, variables=context)
                self.assertFalse(
                    all(
                        templar.evaluate_conditional(condition)
                        for condition in task.changed_when
                    )
                )

    def test_socket_present_is_stopped_and_disabled(self):
        self.assertEqual(
            self.task("systemd").args,
            {"name": "podman.socket", "enabled": False, "state": "stopped"},
        )
        for load_state in ("loaded", "masked", "loaded\n", " \tmasked\r\n"):
            with self.subTest(load_state=load_state):
                context = self.context(["podman"], load_state)
                self.select_packages(context)
                self.assertTrue(self.enabled("command", context))
                self.assertTrue(self.enabled("systemd", context))

    def test_missing_socket_is_skipped_but_packages_are_removed(self):
        for load_state in ("not-found", "not-found\n", " \tnot-found\r\n "):
            with self.subTest(load_state=load_state):
                context = self.context(["toolbox"], load_state)
                self.select_packages(context)
                self.assertTrue(self.enabled("command", context))
                self.assertFalse(self.enabled("systemd", context))
                self.assertTrue(self.enabled("dnf", context))

    def test_present_socket_without_packages_is_skipped(self):
        context = self.context([], "loaded\n")
        self.select_packages(context)
        self.assertFalse(self.enabled("command", context))
        self.assertFalse(self.enabled("systemd", context))

    def test_failures_are_not_hidden(self):
        self.assertFalse(self.block.rescue)
        for action in ("command", "systemd", "dnf"):
            task = self.task(action)
            with self.subTest(action=action):
                # These attributes include settings inherited from the block.
                self.assertFalse(task.ignore_errors)
                self.assertFalse(task.ignore_unreachable)
                self.assertFalse(task.failed_when)
                if action == "command":
                    self.assertFalse(task.become)
                else:
                    self.assertTrue(task.become)

    def test_dnf_transaction_contract(self):
        task = self.task("dnf")
        self.assertEqual(
            task.args,
            {
                "name": "{{ installed_podman_packages }}",
                "state": "absent",
                "allowerasing": True,
                "autoremove": False,
            },
        )
        self.assertEqual(task.register, "podman_removal")
        self.assertFalse(task.loop)  # One list/transaction, not one per package.

    def test_debug_reports_registered_transaction_results(self):
        task = self.task("debug")
        self.assertEqual(task.args, {"var": "podman_removal.results"})
        context = self.context(["podman"])
        self.select_packages(context)
        results = ["Removed: podman", "Removed: toolbox"]
        context["podman_removal"] = {"results": results}
        self.assertTrue(self.enabled("debug", context))
        value = Templar(loader=self.loader, variables=context).evaluate_expression(
            trust_as_template(task.args["var"])
        )
        self.assertEqual(value, results)

    def test_nodocker_marker_contract(self):
        task = self.task("file")
        self.assertEqual(
            task.args, {"path": "/etc/containers/nodocker", "state": "absent"}
        )
        self.assertTrue(task.become)


if __name__ == "__main__":
    unittest.main()
