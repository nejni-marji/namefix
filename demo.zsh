#!/bin/zsh

alias BAR='printf '\''%0.s#'\'' {1..$COLUMNS} ; print'

if ! which rsync ; then
	echo 'Unable to find rsync'
	exit 10
fi


echo "Resetting tests folder from tests.bck..."
rsync -ha ./tests.bck/ tests/ --delete


echo "Entering tests folder..."
cd ./tests/

BAR

../namefix-meta.zsh JohnSmith AliceJones 3

cd $OLDPWD
