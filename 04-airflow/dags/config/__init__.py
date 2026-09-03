"""Raw event -> Bronze table configuration package.

Present so that `config` is a regular package rather than an implicit namespace
package. `config` is a common directory name; without this file, another
`config/` anywhere on sys.path could be merged into the same namespace and
shadow this one.
"""
