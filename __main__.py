#!/usr/bin/env python3

import argparse
import os
import pathlib
import textwrap

from log import log

PLAYBOOKS_DIRECTORY = pathlib.Path("./playbooks")


def run_playbook(playbook_name, prompt_sudo_password):
    entrypoint = PLAYBOOKS_DIRECTORY / playbook_name / "main.yml"
    ansible_cmd = f"ansible-playbook -i hosts.ini {entrypoint}"
    if prompt_sudo_password:
        ansible_cmd += " -K"

    os.system(ansible_cmd)


def run_playbook_task(playbook_name, task, prompt_sudo_password):
    entrypoint = PLAYBOOKS_DIRECTORY / playbook_name / f"{task}.yml"
    if not os.path.isfile(entrypoint):
        log.error(f"Could not find task file at '{entrypoint}'")
        return
    log.info(f"Found task file at '{entrypoint}'")

    ansible_cmd = f"ansible all -i hosts.ini -m include_tasks -a '{entrypoint}'"
    if prompt_sudo_password:
        ansible_cmd += " -K"

    os.system(ansible_cmd)


parser = argparse.ArgumentParser(
    prog="tools",
    description="NUCCDC tools CLI.",
)

playbook_choices = [dir.name for dir in os.scandir(PLAYBOOKS_DIRECTORY) if dir.is_dir()]

parser.add_argument("-p", "--playbook", required=True, choices=playbook_choices)
parser.add_argument("-t", "--task", required=False)
parser.add_argument("-K", "--prompt-sudo-password", required=False, action="store_true")

args = parser.parse_args()
playbook = args.playbook
task = args.task
prompt_sudo_password = args.prompt_sudo_password

if task:
    log.info(f"Running playbook '{playbook}' with task '{task}'")
    run_playbook_task(playbook, task, prompt_sudo_password)
else:
    log.info(f"Running playbook '{playbook}'")
    run_playbook(playbook, prompt_sudo_password)
