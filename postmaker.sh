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

# Define a function to escape special characters in content
sanitize () { sed 's_[_&\]_\\&_g'; }

# Define functions to retrieve data from a raw post file
get_tags () { sed -n '3p' | grep -wo '[[:alnum:]]*' | sanitize; }
get_desc () { sed -n '2p' | sanitize; }
get_title () { sed -n '1p' | sanitize; }
get_content () { tail --lines=+4 | markdown | tr '\n' ' ' | sanitize; }

# Define functions to insert content into a template
insert () { sed "s_!${1}!_${2}_g"; }
insert_content () { insert 'CONTENT' "$(cat $1 | get_content)"; }
insert_entries () { insert 'ENTRIES' "$(cat $1)"; }
insert_title () { insert 'POSTNAME' "$(cat $1 | get_title)"; }
insert_desc () { insert 'POSTDESC' "$(cat $1 | get_desc)"; }
insert_post_link () { insert 'POSTFILENAME' $1; }
insert_index_title () { insert 'INDEXNAME' $1; }
#insert_tags () { ; }
#insert_tag_link () { ; }

# Loop through and process all raw post files in the raw file directory
for RAW_FILE in $RAW_DIR*
do
			
	# Insert title and content into post template
	echo -n "Processing file '$(basename $RAW_FILE)'..."
	cat $POST_TEMPLATE | insert_content $RAW_FILE | insert_title $RAW_FILE > $POSTS_DIR$(basename RAW_FILE).html
	echo -ne "\e[1;32m Done.\e[0m"

	# Create a truncated version of the post for index pages
	POST_LINK=/$(basename $POSTS_DIR)/$(basename $RAW_FILE).html
	entry=$(cat $ENTRY_TEMPLATE | insert_title $RAW_FILE | insert_desc $RAW_FILE | insert_post_link $POST_LINK)

	# Process each tag
	for tag in $(cat $RAW_FILE | get_tags)
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

# Build an index page for each tag
TAG_DIRS=$(ls $TAGS_DIR)
for TAG_DIR in $TAG_DIRS
do
	index=$TAGS_DIR$TAG_DIR/index.html
	cat $INDEX_TEMPLATE | insert_entries $index | insert_index_title $TAG_DIR > $TAGS_DIR$TAG_DIR/index.html
done

# Build main index by adding the list of all entries into the index template
cat $INDEX_TEMPLATE | insert_entries $MAIN_INDEX_FILE | insert_index_title "Blog" > $MAIN_INDEX_FILE
