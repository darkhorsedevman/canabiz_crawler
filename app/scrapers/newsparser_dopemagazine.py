#!/usr/bin/python
# -*- coding: UTF-8 -*-

from lxml import html
import requests
from datetime import datetime
import json

from news import NewsSite, INewsParser

class NPDopeMagazine(INewsParser):
    def __init__(self):
        self.url = 'http://www.dopemagazine.com/category/news/'

    def parse(self):
        site = NewsSite(self.url)
        home_raw = requests.get(self.url, headers = self.headers)
        home = html.fromstring(home_raw.content)

        excerpts = home.xpath('//div[contains(@class, "mp-container")]')

        for excerpt in excerpts:
            title = excerpt.xpath('.//h2/a/text()')[0].strip()
            
            url = excerpt.xpath('.//h2/a/@href')[0]
            article_raw = requests.get(url, headers = self.headers)
            article = html.fromstring(article_raw.content)
            for script in article.xpath('//script'):
                script.getparent().remove(script)
            for style in article.xpath('//style'):
                style.getparent().remove(style)
            for div in article.xpath('//div[contains(@class, "essb_links")]'):
                div.getparent().remove(div)
            image_url = None
            image_raw = article.xpath('.//meta[@property="og:image"]/@content')
            if len(image_raw):
                image_url = image_raw[0]
            if len (article.xpath('//div[@class="metathings"]//time/@datetime')):
                date_raw = article.xpath('//div[@class="metathings"]//time/@datetime')[0]
                date = datetime.strptime(date_raw.strip()[:10], "%Y-%m-%d")
            if len (article.xpath('//div[@class="entry-content"]')):    
                body_html_raw = article.xpath('//div[@class="entry-content"]')[0]
                body_html = html.tostring(body_html_raw)
                body_text = body_html_raw.text_content().strip()

            site.add_article(title, url, image_url, date, body_html, body_text)

        return site.to_dict()


def parse_site():
    parser = NPDopeMagazine()
    return parser.parse()

if __name__ == '__main__':
    print json.dumps(parse_site())
