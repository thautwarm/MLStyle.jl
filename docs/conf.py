import sys
sys.path.append('.')
import sphinx_bootstrap_theme
from pygments.lexer import RegexLexer
from pygments import token
from sphinx.highlighting import lexers
from pygments.style import Style
from re import escape
from pygments_julia import *
from version import version

lexers['julia'] = Julia1Lexer(startinline=True)
lexers['julia-console'] = Julia1Lexer(startinline=True)

project = 'MLStyle.jl'
copyright = '2020, thautwarm'
author = 'thautwarm'
release = '0.4.0'

# Add any paths that contain custom static files (such as style sheets) here,
# relative to this directory. They are copied after the builtin static files,
# so a file named "default.css" will overwrite the builtin "default.css".
html_static_path = ['_static']
language = None
exclude_patterns = ["build", "_build", "_sources", ".shadow", "Thumbs.db", ".DS_Store"]

# class WurusaiStyle(Style):
#     background_color = "#FFFFAA"
#     styles = {
#         token.Text: "#AA3939",
#         token.String: "#479030",
#         token.Keyword: "#A600A6",
#         token.Operator: "#246C60",
#         token.Number: "#779D34",
#         token.Comment: "#AA6F39",
#         token.Punctuation: "#DE369D",
#         token.Literal: "#4671D5",
#     }

# def pygments_monkeypatch_style(mod_name, cls):
#     import sys
#     import pygments.styles

#     cls_name = cls.__name__
#     mod = type(__import__("os"))(mod_name)
#     setattr(mod, cls_name, cls)
#     setattr(pygments.styles, mod_name, mod)
#     sys.modules["pygments.styles." + mod_name] = mod
#     from pygments.styles import STYLE_MAP

#     STYLE_MAP[mod_name] = mod_name + "::" + cls_name


# pygments_monkeypatch_style("wurusai", WurusaiStyle)
pygments_style = "colorful"

extensions = ["sphinx.ext.mathjax", "recommonmark", "sphinx.ext.githubpages"]
templates_path = ["_templates"]
master_doc = "index"
todo_include_todos = True

Topics = [
    "Syntax",
    "Modules",
    "Tutorials"
]

html_theme = "bootstrap"
html_theme_path = sphinx_bootstrap_theme.get_html_theme_path()
html_title = "MLStyle.jl Documentation"
html_theme_options = {
    # Navigation bar title. (Default: ``project`` value)
    "navbar_site_name": f"{project}",
    "navbar_title": f"{project}",
    "navbar_links": [("GitHub", "https://github.com/thautwarm/MLStyle.jl", True)],
    # Render the next and previous page links in navbar. (Default: true)
    "navbar_sidebarrel": True,
    # Render the current pages TOC in the navbar. (Default: true)
    "navbar_pagenav": True,
    # Tab name for the current pages TOC. (Default: "Page")
    "navbar_pagenav_name": "Structure",
    # Global TOC depth for "site" navbar tab. (Default: 1)
    # Switching to -1 shows all levels.
    "globaltoc_depth": -1,
    # Include hidden TOCs in Site navbar?
    #
    # Note: If this is "false", you cannot have mixed ``:hidden:`` and
    # non-hidden ``toctree`` directives in the same page, or else the build
    # will break.
    #
    # Values: "true" (default) or "false"
    "globaltoc_includehidden": "true",
    # HTML navbar class (Default: "navbar") to attach to <div> element.
    # For black navbar, do "navbar navbar-inverse"
    "navbar_class": "navbar navbar-inverse",
    # Fix navigation bar to top of page?
    # Values: "true" (default) or "false"
    "navbar_fixed_top": "false",
    # Location of link to source.
    # Options are "nav" (default), "footer" or anything else to exclude.
    "source_link_position": "footer",
    # Bootswatch (http://bootswatch.com/) theme.
    #
    # Options are nothing (default) or the name of a valid theme
    # such as "cosmo" or "sandstone".
    #
    # The set of valid themes depend on the version of Bootstrap
    # that's used (the next config option).
    #
    # Currently, the supported themes are:
    # - Bootstrap 2: https://bootswatch.com/2
    # - Bootstrap 3: https://bootswatch.com/3
    "bootswatch_theme": "Readable",
    # Choose Bootstrap version.
    # Values: "3" (default) or "2" (in quotes)
    "bootstrap_version": "3",
}
# Theme options are theme-specific and customize the look and feel of a theme
# further.  For a list of options available for each theme, see the
# documentation.
#
# html_theme_options = {}

# Add any paths that contain custom static files (such as style sheets) here,
# relative to this directory. They are copied after the builtin static files,
# so a file named "default.css" will overwrite the builtin "default.css".

html_static_path = ["static"]

html_favicon = "./favicon.ico"


# Custom sidebar templates, must be a dictionary that maps document names
# to template names.
#
# This is required for the alabaster theme
# refs: http://alabaster.readthedocs.io/en/latest/installation.html#sidebars
html_sidebars = {"**": []}


# -- Options for HTMLHelp output ------------------------------------------

# Output file base name for HTML help builder.
htmlhelp_basename = "mlstyle_"
html_baseurl = f"https://thautwarm.github.io/MLStyle.jl/{version}/"

# -- Options for LaTeX output ---------------------------------------------

latex_elements = {
    # The paper size ('letterpaper' or 'a4paper').
    #
    # 'papersize': 'letterpaper',
    # The font size ('10pt', '11pt' or '12pt').
    #
    # 'pointsize': '10pt',
    # Additional stuff for the LaTeX preamble.
    #
    # 'preamble': '',
    # Latex figure (float) alignment
    #
    # 'figure_align': 'htbp',
}

# Grouping the document tree into LaTeX files. List of tuples
# (source start file, target name, title,
#  author, documentclass [howto, manual, or own class]).
latex_documents = [
    (master_doc, f"{project}.tex", f"{project}", "thautwarm", "manual"),
]


# -- Options for manual page output ---------------------------------------

# One entry per manual page. List of tuples
# (source start file, name, description, authors, manual section).
man_pages = [(master_doc, f"{project}", f"{project}", [author], 1)]


# -- Options for Texinfo output -------------------------------------------

# Grouping the document tree into Texinfo files. List of tuples
# (source start file, target name, title, author,
#  dir menu entry, description, category)
texinfo_documents = [
    (
        master_doc,
        f"{project}",
        f"{project}",
        author,
        f"{project}",
        "MLStyle",
        "Miscellaneous",
    ),
]

epub_title = project
epub_author = author
epub_publisher = author
epub_copyright = copyright
epub_exclude_files = ["search.html"]