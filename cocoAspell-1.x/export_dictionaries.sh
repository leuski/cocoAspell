#! /bin/sh -f

if [ ! -d "Dictionaries" ]
then
	echo "No Dictionaries"
	exit 0
fi

cd "Dictionaries"

for f in `sh -c "ls -d aspell-*"`
do
	if [ -d $f ]
	then
		echo "exporting $f..."
		sh -c "tar cf $f.tar $f/*"
		rm -r $f
		gzip $f.tar
	fi
done

echo "making html..."

html_file_name=dictionaries.html

echo "
<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\"
        \"http://www.w3.org/TR/1999/REC-html401-19991224/loose.dtd\">
<html>
<head>
<title>
cocoAspell dictionaries
</title>
</head>
<body>

<table width=\"500\">
<tr>
<td>

<p>The following are the compiled versions of the <a href=\"http://aspell.sourceforge.net/\">Aspell dictionaries</a> for Mac OS X.</p>

<p>The original (and probably more current) versions of the same dictionaries can be found at <a href=\"http://aspell.sourceforge.net/\">Aspell main site.</a></p>

<p>Disclaimer. These links are not guaranteed to be up-to-date and may disappear at any time.</p>

<table>
" > $html_file_name

sh -c "ls -l *.gz | awk '{printf(\"<tr><td><a href=\\\"http://www-ciir.cs.umass.edu/~leouski/aspell/%s\\\">%s</a></td><td>%5.1fMb</td></tr>\n\", \$9, \$9, \$5/1000000);}'" >> $html_file_name


echo "
</table>

</td>
</tr>
</table>
</body>
</html>
" >> $html_file_name