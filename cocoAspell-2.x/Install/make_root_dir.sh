#/bin/sh -f

files_to_install=$1
root_dir=$2

echo "Installing files from $files_to_install to $root_dir..."

if [ -d "$root_dir" ]
then 
	rm -r "$root_dir"
fi

mkdir -p "$root_dir"

tar -cpf -  -T $files_to_install | (cd "$root_dir"; sudo tar xpf - )