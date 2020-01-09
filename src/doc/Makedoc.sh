#! /bin/bash

set -e

export TMPDIR=`mktemp -d ${TMPDIR:-/tmp}/ldt.XXXXXXXXXX`;

echo "-------- Building linuxdoc-tools docs ---------"
echo "Installed tree: $PREFIX"
echo "Using temporary directory: $TMPDIR"

function abort()
{
     /usr/bin/sleep 1; /bin/rm -rf $TMPDIR; exit 1
}

trap 'abort' 1 2 3 6 9 15

export PERL5LIB=${TMPDIR}:../perl5lib

PERL=`which perl`
TMPDATADIR=${TMPDIR}/linuxdoc-tools

cp -r ${PKGDATADIR} $TMPDIR
cp ../tex/*.sty ${TMPDATADIR}

mkdir $TMPDIR/Text

sed < ../entity-map/EntityMap.pm.in > $TMPDIR/Text/EntityMap.pm \
 -e 's|\@localentitymapdir\@|'${PKGDATADIR}'/../entity-map|g' \
 -e 's|\@entitymapdir\@|'${PKGDATADIR}'/../entity-map/0.1.0|g'

sed < ../bin/linuxdoc.in > $TMPDIR/linuxdoc \
 -e 's!\@prefix\@!'${PREFIX}'!g' \
 -e 's!\@auxbindir\@!'${AUXBINDIR}'!g' \
 -e 's!\@pkgdatadir\@!'${TMPDATADIR}'!g' \
 -e 's!\@perl5libdir\@!'${TMPDIR}'!g' \
 -e 's!\@GROFFMACRO\@!-ms!g' \
 -e 's!\@PERL\@!'${PERL}'!g' \
 -e 's!\@PERLWARN\@!!g'

chmod u+x $TMPDIR/linuxdoc

if [ -n "`which groff`" ]; then
	ln -s $TMPDIR/linuxdoc $TMPDIR/sgml2txt
	echo "- Building txt docs" >&2
	$TMPDIR/sgml2txt -b 1 ./guide
fi

if [ -n "`which latex`" ]; then
	ln -s $TMPDIR/linuxdoc $TMPDIR/sgml2latex
	echo "- Building latex docs" >&2
	$TMPDIR/sgml2latex --pass="\usepackage{times}" -o dvi ./guide
fi

if [ -n "`which dvips`" ]; then
	echo "   + dvips" >&2
	dvips -t letter -o ./guide.ps ./guide.dvi
	if [ -n "`which gzip`" -a -f ./guide.ps ]; then
		gzip -fN ./guide.ps
	fi
fi


echo "- Building info docs" >&2
$TMPDIR/linuxdoc -B info ./guide.sgml

echo "- Building lyx docs" >&2
$TMPDIR/linuxdoc -B lyx ./guide.sgml

echo "- Building html docs" >&2
$TMPDIR/linuxdoc -I -B html ./guide && mv -f ./guide*.html ./html

echo "- Building rtf docs" >&2
$TMPDIR/linuxdoc -B rtf ./guide && if [ ! -d ./rtf ]; \
 then mkdir -m 755 ./rtf; fi && mv -f ./guide*.rtf ./rtf

rm -rf $TMPDIR

exit 0
