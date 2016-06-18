---
title: Usage - crpaste
---
# crpaste

A simplistic, command line focused pastebin.

## Usage

### Create a paste

#### `POST /`

Submit an urlencoded body. The response will include a cookie with a token
needed to explicitly delete the paste. By default the response body will be
the URL of the created paste.

Parameters:

* **expire**: Without a unit: minutes until paste is expired.
  Available units: **s**econds, **m**inutes, **h**ours, **d**ays, **w**eeks, **M**onths, **y**ears

  Example: `/?expire=4w` <br />
  Default: `6h`
* **format**: Append the given format to the URL.
  See `GET /<id>.txt` and `GET /<id>.<format>`.

  Example: `/?format=txt` <br />
  Default: none
* **redirect**: Redirect to the created paste instead of responding with the URL in the body.

  Example: `/?redirect` <br />
  Default: Return URL
* **private**: Mark the paste as private. The response URL will match the token variants.

  Example: `/?private` <br />
  Default: public

Example shell function:

```
crpaste() { param="${1:-txt}"; url="$(curl --data-urlencode @- "BASE_URL/?format=${param/,/&}")"; echo "$url"; }
```

### Retrieve a paste

#### `GET /<id>`

Returns the raw paste with content type `application/octect-stream.

#### `GET /<id>.txt`

Returns the paste with content type `text/plain; charset=utf8`. May fail
if the paste is not valid UTF-8.

#### `GET /<id>.<format>`

Render paste as HTML with line numbers and syntax highlighting in the
language by `format`. Syntax highlighting is done with highlightjs.

#### `GET /<token>/<id>`, `GET /<token>/<id>.txt`, `GET /<token>/<id>.<format>`

Same as above, except for private pastes.

### Delete a paste

#### `DELETE /<id>`

Delete the given paste. The request must include the cookie that was returned by
`POST /`.
