#! /bin/bash

cd ~
for file in bashrc bash_profile bash_logout env func alias; do
	ln -sfv ".config/bash/$file" ".${file}"
done
