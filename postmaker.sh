# Set up filenames and locations
RAW_DIR=$PWD/raw/
POSTS_DIR=$PWD/posts/
TAGS_DIR=$PWD/tags/
TEMPLATE_DIR=$PWD/
POST_TEMPLATE=${TEMPLATE_DIR}post_template.html
INDEX_TEMPLATE=${TEMPLATE_DIR}index_template.html
ENTRY_TEMPLATE=${TEMPLATE_DIR}entry_template.html
MAIN_INDEX_FILE=$PWD/blog.html

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
rm -r $POSTS_DIR $TAGS_DIR $MAIN_INDEX_FILE &> /dev/null
if [ ! -d $POSTS_DIR ] && [ ! -d $TAGS_DIR ] && [ ! -f $MAIN_INDEX_FILE ]
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

# Loop through and process all raw post files
# in the raw file directory
for RAW_FILE in $RAW_DIR*
do
	
	# Make sure content has any special characters escaped
	content=$(tail --lines=+4 $RAW_FILE | markdown | tr '\n' ' ' | sed 's_[&\]_\\&_g')
	
	# Insert title and content into post template
	echo -n "Processing file '$(basename $RAW_FILE)'..."
	title=$(head --lines=1 $RAW_FILE)
	sed "s_!POSTNAME!_${title}_" $POST_TEMPLATE > $POSTS_DIR$(basename $RAW_FILE).html
	sed -i "s_!CONTENT!_${content}_" $POSTS_DIR$(basename $RAW_FILE).html
	echo -ne "\e[1;32m Done.\e[0m"

	# Create the HTML for a truncated version of the post (for listing
	# on index pages
	POST_LINK=/$(basename $POSTS_DIR)/$(basename $RAW_FILE).html
	desc=$(sed -n '2p' $RAW_FILE | sed 's_[&\]_\\&_g')
	# TODO: Fix underscores in raw file filename breaking sed command
	entry=$(sed "s_!POSTFILENAME!_${POST_LINK}_" $ENTRY_TEMPLATE | sed "s_!POSTNAME!_${title}_" | sed "s_!POSTDESC!_${desc}_")

	# Catch all tags
	echo -n ' Processing tags...'
	tags=$(sed -n '3p' $RAW_FILE | grep -wo '[[:alnum:]]*')

	# Process each tag
	for tag in $tags
	do
		# Make a directory for the tag, if not already present
		mkdir --parents $TAGS_DIR$tag

		# Append this post's truncated info to a list of all posts with this tag
		echo $entry >> $TAGS_DIR$tag/index.html

	done
	echo -e "\e[1;32m Done.\e[0m"

	# Add this post's truncated info to the main index
	echo $entry >> $MAIN_INDEX_FILE
done

# Build an index for each tag
tags=$(ls $TAGS_DIR)
for TAG_DIR in $tags
do
	TAG_DIR=$TAGS_DIR$TAG_DIR
	index=$(sed 's_[&\]_\\&_g' $TAG_DIR/index.html)
	sed "s_!CONTENT!_${index}_" $INDEX_TEMPLATE > $TAG_DIR/index.html
	sed -i 's_!INDEXNAME!_Blog_g' $TAG_DIR/index.html
done

# Build main index by adding the list of all entries into the index template
index=$(sed 's_[&\]_\\&_g' $MAIN_INDEX_FILE)
sed "s_!CONTENT!_${index}_" $INDEX_TEMPLATE > $MAIN_INDEX_FILE
sed -i 's_!INDEXNAME!_Blog_g' $MAIN_INDEX_FILE
