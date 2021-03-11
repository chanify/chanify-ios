# Chanify

[![iTunes App Store](https://img.shields.io/itunes/v/1531546573?logo=apple&style=flat-square)](https://itunes.apple.com/app/id1531546573)
[![GitHub](https://img.shields.io/github/license/chanify/chanify-ios?style=flat-square)](LICENSE)

<a href="https://www.producthunt.com/posts/chanify?utm_source=badge-featured&utm_medium=badge&utm_souce=badge-chanify" target="_blank"><img src="https://api.producthunt.com/widgets/embed-image/v1/featured.svg?post_id=287376&theme=light" alt="Chanify - Safe and simple notification tools | Product Hunt" style="width: 185px; height: 40px;" width="185" height="40" /></a>

Chanify is a safe and simple notification tools. For developers, system administrators, and everyone can push notifications with API.

## Getting Started

1. Install [iOS App](https://itunes.apple.com/us/app/id1531546573).
2. Get token from channel detail
   
    ![Get token](Doc/GetToken.gif)

3. Send message
4. You can create your channel

    ![NewChannel](Doc/NewChannel.gif)

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
$ curl --form-string "text=hello" "https://api.chanify.net/v1/sender/<token>"
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
