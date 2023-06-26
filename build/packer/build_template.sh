#!/bin/bash

to_existing_realpath() {
  mkdir -p $1
  realpath $1
}

ARTIFACTS_DIR=$(to_existing_realpath "./../../artifacts/packer/$*")
OUTPUT_DIR=$(to_existing_realpath "${ARTIFACTS_DIR}/$*.dir")
TEMPLATE_FILE=./templates/$*-template.pkr.hcl

echo "*** ARTIFACTS_DIR: ${ARTIFACTS_DIR}"
echo "*** OUTPUT_DIR   : ${OUTPUT_DIR}"
echo "*** TEMPLATE_FILE: ${TEMPLATE_FILE}"

echo "*** Packer Build: Generate the Container Filesystem Tarball"
packer build \
  -var=output_dir=${ARTIFACTS_DIR} \
  -var-file=./vars/$*.pkrvars.hcl \
  -only="gen-fs-tarball.*" ${TEMPLATE_FILE}

echo "Extracting tarball to a directory.."
tar -vxf ${ARTIFACTS_DIR}/$*.tar -C ${OUTPUT_DIR}

echo "*** Packer Build: Generate boot image"
packer build \
  -var=output_dir=${OUTPUT_DIR} \
  -var=artifacts_dir=${ARTIFACTS_DIR} \
  -var-file=./vars/$*.pkrvars.hcl \
  -only="gen-boot-img.*" ${TEMPLATE_FILE}

echo "*** Cleanup temp files..."
rm -rf mnt "${OUTPUT_DIR}"
rm -f "${ARTIFACTS_DIR}/$*.img"
rm -f "${ARTIFACTS_DIR}/$*.tar"
