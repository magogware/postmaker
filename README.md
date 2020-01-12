# postmaker
postmaker is designed to be an easy-to-use and barebones page generator
for websites. Feed in some templates and (easy-to-write) post files and
postmaker will spit out HTML the way you like it.

## How to use
### Structure of a postmaker site
It's a lot easier to understand how to use postmaker if you know what
the structure of a generated site will look like. Basically, you'll
have some index files (which are like lists with truncated or shortened
versions of your posts), and a page for each post (with all the content
in full). postmaker will generate one super index page with *all* your
posts on it, as well as index pages for each tag that appears in your
posts. Your main index page will be in the root (base) folder of your
site, and the tag index pages will be under tags/tagname (with the
example configuration, that is). Your post files will be under the posts
folder.
### What templates you'll need
To make postmaker run, you'll need four templates. One is for your
index pages, one is for your post pages, one is for your entries (i.e.:
the shortened versions of posts for your index pages), and one is for
your tags. Those last two ones probably won't be big templates, but will
just have a little HTML so that your CSS works nicely (things like classes
and ids).
Each template has a couple fields that need to appear *somewhere* so postmaker
knows where to put stuff. If you check the example templates, you'll see
what those are for each type of template.
### How to write a post
Post writing is super simple. On the first line, you'll need the title of
the post (so that your HTML page and your entry for that post have a title).
On the second line, you'll want a short description (again, for the index
pages). On the third line, add as many tags as you want, separated by a space.
From the fourth line onwards, you can put all the content you want, written
in markdown.
### But most importantly...
Check the example templates and example post (under raw/example). They'll
give you a great idea of what you need to feed postmaker to make it happy.
