# dumbassCMS

I was in search of a very basic CMS where I could drop markdown files and have them automatically rendered into HTML pages using a basic template and my own user-specified styles. Instead, I found a lot of full-featured pro-pen source CMSes with themes, plugins, available support contracts, and whatnot, and invariably they didn't work out-of-the-box. After some time struggling with debugging some very basic changes I imagine every user of one of these CMSes would want to make (like removing CMS attribution footers and extraneous pathinfo from the URL), I finally gave up and wrote my own bare-bones CMS that uses GNU make, bash, and python-markdown to dump static HTML files into a tree for serving up via your favorite web server.

## Note well

This thing is intended for use of self-generated content only. The templating "system", such as it is, runs whatever bash code is specified in the template and content files! That means you do not want to include user-generated content (i.e., *adversary*-generated content) in the rendering process. This thing is completely insecure as-is if you naively add commenting, file upload, or other content injection mechanisms without taking great care to exclude them from the template rendering process.

## Preparation

On Debian, install `python3-markdown`, `python3-pymdownx` (for the SuperFences extension), and `yq` (which will also bring in `jq`). Do whatever is equivalent on your distro.

## Configuration

### Makefile

Maybe I'll eventually move the configuration into a separate file, but right now config for CMS build automation comprises a set of variables at the top of the Makefile:

* `contentroot`: the location of the markdown content that is rendered into HTML pages. **This does not need to be in the webroot.**
* `renderedroot`: the output directory tree into which rendered HTML is dropped by the CMS
* `stateroot`: a directory containing durable state files produced and used by the CMS. **This does not need to be in the webroot.**
* `urlroot`: the pathinfo for the base URL `scheme://your.hostname/<urlroot>` pointing at the root of your rendered documents, without a trailing `/`. This will be empty if you use the server root, but will be something like `/~user` if you use your home directory's `public_html`.

This software's correctness is sensitive to not including a trailing `/` on any of the above variables.

### Page template

`base.html.tmpl` is the template used to render each of your site's pages. As noted in the introduction, it has bash code embedded in it, unimaginatively signified by the use of `{%bash ... %}` tags throughout. This bash code can (and probably mostly will) reference functions from the `bash_functions` script and can be used to do *anything* the user running `make` can do so *beware content you did not self-generate*. The main functions you'll want to use are:

* `title`: Emits the page title.
* `html-nav-path`: Emits a tree-structured unordered list of some subset of the site pages. Experiment to find out which!
* `render-content`: Emits the content of the current page, itself run through the template rendering process for completeness and the ultimate in FAFO if you decide to allow user-generated content into your site.
* `page-url`: Kinda a lie, it emits the `urlroot` concatenated with the page location within the content tree, so usually just pathinfo.

Each of these functions also takes an optional page location if you don't want to use the current page location for whatever reason.

Otherwise, you can put any damn thing you like in the template. The example references highlight.js and my prototype site CSS, the latter of which I have included under `examples/`.

### Apache

Since my site lives in my home directory's `public_html` subdirectory, I use the following `.htaccess` in that directory to rewrite bare URLs that don't match existing asset files into requests for the rendered HTML under the `rendered` subdirectory. There is also a whitelist of valid asset directories, and indexes are turned off, to prevent users from getting access to stuff that shouldn't be publicly available.

```
<IfModule mod_rewrite.c>
    RewriteEngine On

    # Deny access to things that shouldn't really live in the web root anyway
    RewriteCond %{REQUEST_FILENAME} -f
    RewriteRule !^(\.?well-known|assets|graphics|rendered|styles|index.html|)(/|$) notfound [END]

    # Enable URL rewriting
    RewriteCond %{REQUEST_FILENAME} !-f
    #RewriteCond %{REQUEST_FILENAME} !-d
    RewriteCond %{REQUEST_URI} !/rendered/
    RewriteRule ^(.*)$ rendered/$1 [L]

    RewriteCond %{REQUEST_FILENAME}.html -f
    RewriteRule (.*) $1.html [END]
</IfModule>

DirectoryIndex index.html

# Prevent file browsing
Options -Indexes -MultiViews
```

## Building

Edit the Makefile and template as desired, make sure your content is all in the right place, and then run `make`. Voila!

A speed demon this CMS is not. I'm not exactly sure why it's so slow, but it does a lot of bash string manipulation, which is probably not the most efficient mechanism possible. But you know what? Willy hears ya; Willy don't care.

## Support

There is none, and I am accepting no Issues. I put this on GitHub because someone somewhere might have similarly simple needs for a CMS, not because I want this to turn into bloatware. I recommend forking and implementing new features yourself if you want something.
