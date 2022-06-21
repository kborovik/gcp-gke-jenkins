#!/bin/bash
set -e
echo "Disable Setup Wizard"
echo $JENKINS_VERSION >/var/jenkins_home/jenkins.install.UpgradeWizard.state
echo $JENKINS_VERSION >/var/jenkins_home/jenkins.install.InstallUtil.lastExecVersion
echo "Settings Bash aliases"
echo "alias ls='ls --color -F'; alias ll='ls -lh'" >/var/jenkins_home/.bashrc
echo "All done! The End."
