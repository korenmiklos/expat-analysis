import requests
import credentials 
from lxml import html
import os
import codecs
import sys

class Session(object):
	def __init__(self, module):
		self.session = requests.session()
		self.url = module.url
		self.login_url = '{}/login/?next=/'.format(self.url)
		self.username = module.username
		self.password = module.password

		result = self.session.get(self.login_url)
		tree = html.fromstring(result.text)
		self.authenticity_token = list(set(tree.xpath("//input[@name='csrfmiddlewaretoken']/@value")))[0]

	def login(self):
		result = self.session.post(
			self.login_url, 
			data=dict(username=self.username, password=self.password, csrfmiddlewaretoken=self.authenticity_token), 
			headers=dict(referer=self.login_url)
		)

	def get(self, path):
		url = '{}{}'.format(self.url, path)
		return self.session.get(url, headers=dict(referer=url))


def cegs_by_tax_id(session, tax_id):
	url = '/cegs_by_tax_id/{}'.format(tax_id)
	response = session.get(url)
	if response.ok:
		tree = html.fromstring(response.text)
		ceg_ids = list(set([c.text_content() for c in tree.xpath("//td[@class='ceg_id']")]))
		return ceg_ids
	else:
		return []

def ceg(session, ceg_id):
	url = '/ceg/{}'.format(ceg_id)
	response = session.get(url)
	if response.ok:
		return response.text
	else:
		return ''

def get_by_frame_id(session, frame_id):
	tipus = frame_id[0:2]
	azon = frame_id[2:]

	if tipus == 'ft':
		ceg_ids = cegs_by_tax_id(session, azon)
	else:
		ceg_ids = [azon]

	print(ceg_ids)

	return {cgj: ceg(session, cgj) for cgj in ceg_ids}

def write_by_frame_id(session, frame_id):
	firms = get_by_frame_id(session, frame_id)
	if firms:
		try:
			os.makedirs(frame_id)
		except:
			pass
		for firm in firms:
			with codecs.open('{}/{}.html'.format(frame_id, firm), 'wt', 'utf-8') as file:
				file.write(firms[firm])

if __name__ == '__main__':
	complexweb = Session(credentials)
	complexweb.login()

	# expext one frame_id in each line on stdin
	with sys.stdin as file:
		for line in file.readlines():
			write_by_frame_id(complexweb, line.strip())
