#!/bin/zsh

# we want this form of rsync
alias rsync='rsync -ha'

typeset    old=$1
typeset    new=$2
typeset    mode=$3
typeset -a scan=($4)

# check variables

if [[ $1 =~ '-h|--help|help' ]] || [[ -z $old ]] || [[ -z $new ]] ; then
	echo "Usage: $0 OLDNAME NEWNAME [MODE] [FILE]"
	echo ""
	echo "This program will search files and replace '/home/OLDNAME/' with '/home/NEWNAME/'. It will show the changes being made for each file, and you can select whether or not to save those changes. This program will also show all instances of OLDNAME, even if they are not part of a path. In this case, you can use mode 3 to replace these, if desired." | fold -sw 80
	echo ""
	echo "Additionally, this program will store the original versions of any files that it modifies as *.namefix.bck, just in case a mistake is made." | fold -sw 80
	echo ""
	echo "MODE 1 replaces /home/OLDNAME/"
	echo "MODE 2 replaces /home/OLDNAME"
	echo "MODE 3 replaces OLDNAME"
	echo "FILE may be exactly one file (default: *)"
	echo "(By default, FILE will match all files in the current directory)"
	exit 10
fi
if [[ -z $mode ]] ; then
	mode=1
fi

if [[ -z $scan ]] ; then
	scan=(*)
fi

# begin program

echo "OLD: $old\nNEW: $new"

read '?Is this correct? [y/N] ' resp
if ! [[ $resp =~ 'y|yes|Y|YES' ]] ; then
	echo "Exiting..."
	exit 15
else
	echo "Continuing..."
fi

# begin search

typeset -a targets=("${(f)$(
	grep --binary-file=without-match -Fr -e "$old" -l ${(@)scan}
	)}")

# check targets

if [[ -z $targets ]] ; then
	echo "No targets found, exiting..."
	exit 20
fi

# look for rsync

if ! which rsync ; then
	echo "Unable to find rsync, exiting..."
	exit 30
fi

# look for perl

if ! which perl ; then
	echo "Unable to find perl, exiting..."
	exit 40
fi

# define function

namefix-internal() {
	# set external vars
	old=$1
	new=$2
	mode=$3
	file=$4
	# create .namefix and .namefix.bck
	temp="$file.namefix"
	back="$file.namefix.bck"
	rsync "$file" "$temp"
	rsync "$temp" "$back"
	# sanity check
	if ! [[ -f $file ]] ; then
		echo "Cannot find file: $file"
		return 5
	fi

	# select by mode
	case $mode in
		1)
			replace='s#/home/'"$old"'(/)#/home/'"$new"'\1#g'
			;;
		2)
			replace='s#/home/'"$old"'(/?)#/home/'"$new"'\1#g'
			;;
		3)
			replace='s#'"$old"'#'"$new"'#g'
			;;
		*)
			return 7
			;;
	esac
	# find and replace from $file to $temp
	< "$file" perl -pe "$replace" > "$temp"

	# check changes
	echo "##### Showing \e[1;30;44m SEARCH \e[0m for: \e[1;30;42m $file \e[0m #####"
	< "$file" grep --color=auto -F "$old"
	echo "##### Showing \e[1;30;44m DIFF \e[0m for: \e[1;30;42m $file \e[0m #####"
	diff --color=auto $file $temp
	# end checking changes
	echo "##### Confirming \e[1;30;44m CHANGES \e[0m for: \e[1;30;42m $file \e[0m #####"
	read '?Is this okay? [y/N] ' resp
	if ! [[ $resp =~ 'y|yes|Y|YES' ]] ; then
		echo "Skipping..."
		sleep 0.5
		rm $temp
		return 10
	else
		echo "Writing..."
		< "$temp" > "$file"
		rm $temp
	fi
}

for target in $targets ; do
	if [[ $target =~ '\.namefix$|\.namefix\.bck$' ]] ; then
		continue
	fi
	namefix-internal $old $new $mode $target
done
