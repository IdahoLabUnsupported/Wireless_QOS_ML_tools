#!/bin/bash

for TESTFILE in /home/fs/ldrd/files/*; do
    du -b $TESTFILE
done
