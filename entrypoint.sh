#!/bin/bash
echo "ARTIFACT_NAME: $ARTIFACT_NAME"
echo "REPO_URL: $REPO_URL"
echo "GITHUB_SHA: $GITHUB_SHA"
echo "GITHUB_RUN_NUMBER: $GITHUB_RUN_NUMBER"

PACKAGE=`yq e .template.package helm.yaml`
helm repo add remote-repo $REPO_URL --username $REPO_USER --password $REPO_PASS && helm repo update
helm fetch remote-repo/${PACKAGE} --version `yq e '.template.version //0'  helm.yaml`

find . -name ${PACKAGE}-*.tgz -maxdepth 1 -exec tar -xvf {} \;
mv ${PACKAGE} ${ARTIFACT_NAME}
cd ${ARTIFACT_NAME}

sed -i.bak "s#name: ${PACKAGE}#name: ${ARTIFACT_NAME}#"  Chart.yaml
yq eval-all -i 'select(filename == "values.yaml") * select(filename == "../helm.yaml")' values.yaml ../helm.yaml

yq eval -i '.image.tag = "'${VERSION}'"' values.yaml
helm package --app-version ${VERSION} --version $GITHUB_RUN_NUMBER .
curl -u $REPO_USER:$REPO_PASS -T ${ARTIFACT_NAME}-${GITHUB_RUN_NUMBER}.tgz "$HELM_REPO_URL/${ARTIFACT_NAME}-${GITHUB_RUN_NUMBER}.tgz"

echo "::set-output name=uploaded_file::${REPO_URL}/${ARTIFACT_NAME}-${GITHUB_RUN_NUMBER}.tgz"

