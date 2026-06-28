#!/usr/bin/env bash
# Cria o job Pipeline no Jenkins via REST API.
set -euo pipefail

JENKINS_CONTAINER="${JENKINS_CONTAINER:-jenkins}"
JENKINS_URL="${JENKINS_URL:-http://localhost:8080}"
JOB_NAME="${JOB_NAME:-biblioteca-api-pipeline}"
GIT_URL="${GIT_URL:-https://github.com/leticiaafigueiredo/tp2-gerencia-conf.git}"
GIT_BRANCH="${GIT_BRANCH:-*/main}"
ADMIN_PASSWORD="${JENKINS_PASSWORD:-$(docker exec "${JENKINS_CONTAINER}" cat /var/jenkins_home/secrets/initialAdminPassword)}"

COOKIE_JAR="$(mktemp)"
trap 'rm -f "${COOKIE_JAR}" /tmp/jenkins-job-response.txt' EXIT

CRUMB="$(curl -sf -c "${COOKIE_JAR}" -u "admin:${ADMIN_PASSWORD}" \
  "${JENKINS_URL}/crumbIssuer/api/json" | python3 -c "import sys,json; print(json.load(sys.stdin)['crumb'])")"

JOB_XML="$(cat <<EOF
<?xml version='1.1' encoding='UTF-8'?>
<flow-definition plugin="workflow-job">
  <actions/>
  <description>Pipeline Biblioteca API - Build, Test, Acceptance, Deploy</description>
  <keepDependencies>false</keepDependencies>
  <properties/>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition" plugin="workflow-cps">
    <scm class="hudson.plugins.git.GitSCM" plugin="git">
      <configVersion>2</configVersion>
      <userRemoteConfigs>
        <hudson.plugins.git.UserRemoteConfig>
          <url>${GIT_URL}</url>
        </hudson.plugins.git.UserRemoteConfig>
      </userRemoteConfigs>
      <branches>
        <hudson.plugins.git.BranchSpec>
          <name>${GIT_BRANCH}</name>
        </hudson.plugins.git.BranchSpec>
      </branches>
      <doGenerateSubmoduleConfigurations>false</doGenerateSubmoduleConfigurations>
      <submoduleCfg class="empty-list"/>
      <extensions/>
    </scm>
    <scriptPath>Jenkinsfile</scriptPath>
    <lightweight>false</lightweight>
  </definition>
  <triggers/>
  <disabled>false</disabled>
</flow-definition>
EOF
)"

create_job() {
  curl -s -o /tmp/jenkins-job-response.txt -w "%{http_code}" \
    -b "${COOKIE_JAR}" -c "${COOKIE_JAR}" \
    -u "admin:${ADMIN_PASSWORD}" \
    -H "Jenkins-Crumb: ${CRUMB}" \
    -X POST \
    -H "Content-Type: application/xml" \
    --data-binary "${JOB_XML}" \
    "${JENKINS_URL}/createItem?name=${JOB_NAME}"
}

update_job() {
  curl -sf \
    -b "${COOKIE_JAR}" -c "${COOKIE_JAR}" \
    -u "admin:${ADMIN_PASSWORD}" \
    -H "Jenkins-Crumb: ${CRUMB}" \
    -X POST \
    -H "Content-Type: application/xml" \
    --data-binary "${JOB_XML}" \
    "${JENKINS_URL}/job/${JOB_NAME}/config.xml"
}

HTTP_CODE="$(create_job)"
if [[ "${HTTP_CODE}" == "200" ]]; then
  echo "Job '${JOB_NAME}' criado com sucesso."
elif [[ "${HTTP_CODE}" == "400" ]]; then
  echo "Job '${JOB_NAME}' já existe — atualizando configuração."
  update_job
  echo "Job atualizado."
else
  cat /tmp/jenkins-job-response.txt
  echo "ERRO: falha ao criar job (HTTP ${HTTP_CODE})"
  exit 1
fi

echo "Job disponível em: ${JENKINS_URL}/job/${JOB_NAME}/"
echo "Disparo automático: webhook GitHub + trigger githubPush() no Jenkinsfile"
