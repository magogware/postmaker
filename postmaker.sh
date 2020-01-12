# Run the config file (either the supplied file, or the default config)
source ${1:-$(dirname "$0")/config}

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
mkdir --parents $POSTS_DIR $TAGS_DIR &> /dev/null
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
get_tags () { sed -n '3p' | grep -wo '[[:alnum:]]*'; }
get_desc () { sed -n '2p' | sanitize; }
get_title () { sed -n '1p' | sanitize; }
get_content () { tail --lines=+4 | markdown; }

# Get the line number of a pattern ($1) appearing in stdin
get_line_number_of () { grep -n $1 | grep -Eo '^[^:]+'; }

# Insert a file's ($1) contents at the line number of a pattern ($2) in a file ($3)
insert_file_at_pattern_in () {
	line_num=$(cat $3 | get_line_number_of $2)
	cat $3 | head --lines=$(($line_num - 1)) > tmp
	cat $3 | tail --lines=+$(($line_num + 1)) | cat $1 - >> tmp
	cat tmp > $3
	rm tmp
}

# Define functions to insert content into a template
insert () { sed "s_!${1}!_${2}_g"; }
insert_title () { insert 'POSTNAME' "$(cat $1 | get_title)"; }
insert_desc () { insert 'POSTDESC' "$(cat $1 | get_desc)"; }
insert_post_link () { insert 'POSTFILENAME' $1; }
insert_index_title () { insert 'INDEXNAME' $1; }
insert_tag_name () { insert 'TAGNAME' $1; }
insert_tag_link () { insert 'TAGLINK' $1; }

# Loop through and process all raw post files in the raw file directory
for RAW_FILE in $RAW_DIR*
do
	# Make a complete tag template for each tag and add them to a file
	for tag in $(cat $RAW_FILE | get_tags)
	do
		TAG_LINK=/$(basename $TAGS_DIR)/$tag/index.html
		cat $TAG_TEMPLATE | insert_tag_link $TAG_LINK | insert_tag_name $tag >> tags_file
	done

	# Insert title, content, and tags into post template
	echo -n "Processing file '$(basename $RAW_FILE)'..."
	cat $POST_TEMPLATE | insert_title $RAW_FILE > $POSTS_DIR$(basename $RAW_FILE).html
	cat $RAW_FILE | get_content > content_file
	insert_file_at_pattern_in content_file '!CONTENT!' $POSTS_DIR$(basename $RAW_FILE).html
	insert_file_at_pattern_in tags_file '!TAGS!' $POSTS_DIR$(basename $RAW_FILE).html
	echo -ne "\e[1;32m Done.\e[0m"

	# Create a truncated version of the post for index pages
	POST_LINK=/$(basename $POSTS_DIR)/$(basename $RAW_FILE).html
	cat $ENTRY_TEMPLATE | insert_title $RAW_FILE | insert_desc $RAW_FILE | insert_post_link $POST_LINK >> entry_file
	insert_file_at_pattern_in tags_file '!TAGS!' entry_file

	# Process each tag
	for tag in $(cat $RAW_FILE | get_tags)
	do
		# Make a directory for the tag, if not already present
		mkdir --parents $TAGS_DIR$tag

		# Append this post's truncated info to a temporary file with all entries with this tag
		cat entry_file >> $TAGS_DIR$tag/entries

	done
	echo -n ' Processing tags...'
	echo -e "\e[1;32m Done.\e[0m"

	# Add this post's truncated info to a temporary file containing all entries
	cat entry_file >> entries

	# Remove temporary files
	rm tags_file entry_file content_file
done

# Build an index page for each tag
echo -n 'Creating index pages for tags...'
TAG_DIRS=$(ls $TAGS_DIR)
for TAG_DIR in $TAG_DIRS
do
	temp_entries=$TAGS_DIR$TAG_DIR/entries
	cat $INDEX_TEMPLATE | insert_index_title $TAG_DIR > $TAGS_DIR$TAG_DIR/index.html
	insert_file_at_pattern_in $temp_entries '!ENTRIES!' $TAGS_DIR$TAG_DIR/index.html

	rm $temp_entries
done
echo -e "\e[1;32m Done.\e[0m"

# Build main index by adding the list of all entries into the index template
echo -n 'Creating main index page...'
temp_entries=entries
cat $INDEX_TEMPLATE | insert_index_title Blog > $MAIN_INDEX_FILE
insert_file_at_pattern_in $temp_entries '!ENTRIES!' $MAIN_INDEX_FILE
rm $temp_entries
echo -e "\e[1;32m Done.\e[0m"
