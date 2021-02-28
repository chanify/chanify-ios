# Chanify

[![iTunes App Store](https://img.shields.io/itunes/v/1531546573?logo=apple&style=flat-square)](https://itunes.apple.com/app/id1531546573)
[![GitHub](https://img.shields.io/github/license/chanify/chanify-ios?style=flat-square)](LICENSE)

Chanify is a simple messages app.

## Usage

#### Http API

- __GET__
```
https://api.chanify.net/v1/sender/<token>/<message>
```

- __POST__
```
https://api.chanify.net/v1/sender/<token>
```

Content-Type: 

- ```text/plain```: Body is text message
- ```multipart/form-data```: The block of data("text") is text message
- ```application/x-www-form-urlencoded```: ```text=<url encoded text message>```

#### Command Line

```bash
# Send message
$ curl --form-string="text=hello" "https://api.chanify.net/v1/sender/<token>"
# Send text file
$ cat message.txt | curl -H "Content-Type: text/plain" --data-binary @- "https://api.chanify.net/v1/sender/<token>"
```

#### Python 3

```python
from urllib import request, parse

data = parse.urlencode({ 'text': 'hello' }).encode()
req = request.Request("https://api.chanify.net/v1/sender/<token>", data=data)
request.urlopen(req)
```

#### Ruby

```ruby
require 'net/http'

uri = URI('https://api.chanify.net/v1/sender/<token>')
res = Net::HTTP.post_form(uri, 'text' => 'hello')
puts res.body
```

## Build

```bash
$ pod install
```

## Test push in simulator

```bash
$ make apns text=hello
```
