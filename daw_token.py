#!/usr/bin/python

import requests
import os

import wgtoken
username, token = wgtoken.get_token("INSERT-URL-PATH-HERE")

#print username
print token
