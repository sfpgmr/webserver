'use strict';

import request from 'request-promise-native';
import urls from '../data/blog/hidden/pinglist.js';

async function blogPing(){
  const headers = {
    'Content-Type': 'text/xml'
  };

  const ping = 
  `<?xml version="1.0"?>
  <methodCall>
    <methodName>weblogUpdates.ping</methodName>
    <params>
      <param><value>S.F. Blog</value></param>
      <param><value>https://www.sfpgmr.net/blog/</value></param>
    </params>
  </methodCall>
  `;
  //オプションを定義
  const options = {
    url: 'http://blogsearch.google.co.jp/ping/RPC2',
    method: 'POST',
    headers: headers,
    body: ping,
    timeout: 2000
  };


  for(const url of urls){
    try {
      options.url = url;
      console.log('ping to :' + url);
      console.log(await request(options));
    } catch (e) {
      console.error(e);
    }
  }
}

blogPing();
