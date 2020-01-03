# Set up filenames and locations
POST_TEMPLATE=post_template.html
INDEX_TEMPLATE=index_template.html
ENTRY_TEMPLATE=entry_template.html
RAW_DIR=$PWD/raw/
POSTS_DIR=$PWD/posts/
TAGS_DIR=$PWD/tags/

# Check that template files exist
echo -n 'Finding template files...'
if [ -f $POST_TEMPLATE ] && [ -f $INDEX_TEMPLATE ] && [ -f $ENTRY_TEMPLATE ]
then
	echo -e '\e[1;32m Done.\e[0m'
else
	echo -e '\e[1;31m Failed.\e[0m'
	echo -e '\e[1;31mError: one or more template files missing.\e[0m'
	exit
fi



# Remove any existing posts and tags
# so that we can update them
echo -n 'Removing old posts, tags, and index pages... '
rm -r $POSTS_DIR $TAGS_DIR &> /dev/null

if [ ! -d $POSTS_DIR ] && [ ! -d $TAGS_DIR ]
then
	echo -e '\e[1;32m Done.\e[0m'
else
	echo -e '\e[1;31m Failed.\e[0m'
	echo -e '\e[1;31mError: could not remove old tags and posts. Do you have permission to do so?\e[0m'
	exit
fi

# Recreate directories for posts and tags
echo -n 'Recreating directories for posts and tag index pages...'
mkdir $POSTS_DIR $TAGS_DIR &> /dev/null

# Check that it worked
if [ -d $POSTS_DIR ] && [ -d $TAGS_DIR ]
then
	echo -e '\e[1;32m Done.\e[0m'
else
	echo -e '\e[1;31m Failed.\e[0m'
	echo -e '\e[1;31mError: could not create directories. Do you have permissions to do so?\e[0m'
	exit
fi

# Check to see that the specified directory
# containing raw posts to generate HTML from actually exists
echo -n 'Checking for directory containing raw entries... '
if [ -d $RAW_DIR ]
then
	echo -e "\e[1;32m Found directory '$(basename $RAW_DIR)'.\e[0m"
else
	echo -e "\e[1;31m Failed.\e[0m"
	echo -e "\e[1;31mError: could not find directory '$(basename $RAW_DIR)'\e[0m"
	exit
fi

for f in $RAW_DIR*
do
	echo -n "Processing $(basename $f)..."
	#echo -n " Inserting title..."
	title=$(head --lines=1 $f)
	content=$(tail --lines=+4 $f | markdown)
	sed "s_!POSTNAME!_${title}_" $POST_TEMPLATE > $POSTS_DIR$(basename $f).html
	# TODO: Escape content to avoid interfering with sed command
	sed -i "s_!CONTENT!_${content}_" $POSTS_DIR$(basename $f).html
	#echo -n " Inserting content..."
	echo -e "\e[1;32m Done.\e[0m"
done
