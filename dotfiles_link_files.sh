#!/bin/sh
# Create symbolic links to dot files.
# Copyright (C) 2017, 2018, 2020 Upperstream Software.
# Provided under the ISC License.  See LICENSE.txt file for details.

#set -e
#set -v
#set -x

usage() {
	cat <<-EOF
	Usage:
	$0 [-bnq] [-s set] [-x patterns] [[src_dir] dest_dir]
	$0 -H|-h|--help

	src_dir
	   : source directory where `home` directory containing dotfiles to be linked is.  Current directory is
	     assigned if src_dir is not specified
	dest_dir
	   : destination directory where links are created.  \$HOME is assigned
	     if dest_dir is not specified
	-b : create backup files
	-n : do nothing but just print what is supposed to do
	-q : quiet mode; print nothing unless \`-n' option is specified
	-s set
	   : install specified set of tools; see below list for available sets
	-x patterns
	   : exclude list separated by colon (\`:')
	-H|-h|--help
	   : print this help summary and exit

	Available sets are:

EOF

	for s in dotfiles_install_tools_*.sh; do
		. ./$s && `echo $s | sed s/dotfiles_install_tools_\\\\\([^.]*\\\\\).sh/\\\\1/`_describe_module
	done
}

log() {
	test $print_only -eq 1 -o $quiet_mode -eq 0 && echo $@
}

execute() {
	subshell=0
	if [ x"$1" = x"-s" ]; then
		subshell=1
		shift
	fi
	if [ $subshell -eq 1 ]; then
		log "($*)"
		if [ $print_only -eq 0 ]; then
			sh -c "$*"
		fi
	else
		log $@
		if [ $print_only -eq 0 ]; then
			$@
		fi
	fi
}

excludes=""
backup_dir=""
print_only=0
quiet_mode=0
sets=""

test "$1" = "--help" && { usage; exit 255; }

while getopts bhnqs:x:H opt; do
	case $opt in
	b)   backup_dir=.dotfiles.d/backups/`date +%Y%m%dT%H%M%S`;;
	n)   print_only=1;;
	q)   quiet_mode=1;;
	s)   sets=`printf "$sets\n$OPTARG"`;;
	x)   excludes=$OPTARG;;
	h|H) usage; exit 255;;
	esac
done

shift `expr $OPTIND - 1`

if [ $# -gt 1 ]; then
	src_dir=$1
	dest_dir=$2
elif [ $# -eq 1 ]; then
	src_dir=home
	dest_dir=$1
else
	src_dir=home
	dest_dir=$HOME
fi

if [ "$backup_dir" ]; then
	backup_dir=$dest_dir/$backup_dir
fi

to_exclude() {
	name=`basename $1`
	(
		set -f
		IFS=:
		export IFS
		set -- $excludes
		while [ "$1" ]; do
			case $name in
			$1) return 0;;
			*)  shift;;
			esac
		done
		return 1
	)
	return $?
}

link_files() {
	depth=`expr \`echo $1 | sed s:[^/]::g | wc -c\` + 1`
	for f in `find $1 \( -name ".[!.]*" -o -name "[!.]*" \) -type f`; do
		file=`echo $f | cut -f$depth- -d/`
		(echo $file | grep '^\.dotfiles\.d/') && continue
		to_exclude $f && continue
		target=$2/$file
		if [ -f $target -a ! -h $target ]; then
			if [ "$backup_dir" ]; then
				if [ ! -d $backup_dir ]; then
					execute mkdir -p $backup_dir
				fi
				backup_dest_dir=$backup_dir/`dirname $file`
				if [ ! -d $backup_dest_dir ]; then
					execute mkdir -p $backup_dest_dir
				fi
				execute mv $target $backup_dest_dir/
			fi
		fi
		target_dir=`dirname $target`
		if [ ! -d $target_dir ]; then
			execute mkdir -p $target_dir
		fi
		src=`(cd \`dirname $f\`/; pwd)`/`basename $f`
		execute -s "cd $target_dir; ln -sf $src ."
	done
}

link_files_in_set() {
	_sets_dir=$1
	_set=$2
	_dest_dir=$3
	echo "Create links in $_dest_dir to $_sets_dir/$_set"
	link_files "$_sets_dir"/"$_set" "$_dest_dir"
	if [ -f "$_sets_dir"/"$_set".dependencies ]; then
		while read -r d; do
			(link_files_in_set "$_sets_dir" "$d" "$_dest_dir")
		done < "$_sets_dir"/"$_set".dependencies
	fi
}

echo "Create links in $dest_dir to $src_dir"

link_files $src_dir "$dest_dir"
for s in $sets; do
	if [ -d $src_dir/../sets/"$s" ]; then
		link_files_in_set $src_dir/../sets "$s" "$dest_dir"
	fi
done
