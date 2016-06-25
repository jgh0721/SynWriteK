#! /usr/bin/env python3
# coding: cp1251

# Author: Andrey Kvichansky	<kvichans@mail.ru>
# Revision:	0.5
# Last modification: 13 may 2014

import	sw 
from 	sw 		import ed
from 	sw_cmd	import *	# cmd_SelLeft for set_sel

import re
from itertools	import filterfalse

# Logging
import 	inspect	# stack
LOG	= True		# Do or dont logging
log_gap	= ''	# use only into log()

# Ini location
INI_FILE	= 'syn_kvichans.ini'
INI_SEC		= 'ed_complete'

# For re-matching text as 
#	(...) 
# or 
#	(.(...).(...).)
# Before usage "<",">" will be replaced with "(",")" or "[","]" etc.
REOPCL_			=  r'(([^<>]*(<[^<>]*>[^<>]*)*>)|<([^>]*>))'	# Find only 2 cases: skip inner <.*> or simple next '>'  
REOPCL			= r'<(([^<>]*(<[^<>]*>[^<>]*)*>)|<([^>]*>))'	# Find only 2 cases: skip inner <.*> or simple next '>'  

class Command:
	# Options
	VIEW_TYPE	= 'pop'			# 'pop' / 'dlg' / 'mix'
	VIEW_LNM	= False			# Show line numbers
	MENU_MAX	= 4*3			# Max items in local menu (4*?)
	ORDER		= 'norm'		# 'norm' / 'up-dn' / 'up'
	WRAP		= True			# Show first after last and vice versa
	_C4WRD		= r'.'			# Extra chars are used for complete the word
	CL4EXP		= r'({['		# Chars are used for complete the word '"
		
	def __init__(self):
		# Restore config
		self.VIEW_TYPE	= ini_read('view-type',	self.VIEW_TYPE)
		self.VIEW_LNM	= ini_read('view-lnm',	self.VIEW_LNM)
		self.MENU_MAX	= ini_read('menu-max',	self.MENU_MAX)
		self.ORDER		= ini_read('order',		self.ORDER)
		self.WRAP		= ini_read('wrap', 		self.WRAP)
		self._C4WRD		= ini_read('extra', 	self._C4WRD)
		self.RE4WRD		= r'[\w' +re.escape(self._C4WRD)+']+'	# Chars are used for complete the word
		self.RE4NWRD	= r'[^\w'+re.escape(self._C4WRD)+']+'	# Chars are used for locate a word
		self.CRE4WRD	= re.compile(self.RE4WRD)
		self.CRE4NWRD	= re.compile(self.RE4NWRD)

		# Editor situation
		self.sDoc	= ''	# Last full text 			Is better to store only crc32=zlib.adler32(sDoc)??
		self.pPrp	= -1	# Pos of user selection or last shown proposal 
		self.nSel	= -1	# Len of user selection or last shown proposal. If =0 then not need select proposals
		
		# Proposals
		self.sTx4Q	= ''	# Text for query
		self.lPrps	= None	# List [(pos,prp)] - all proposals for sTx4Q
		self.iPrp	= -1	# index in lPrps of shown proposal
		self.sPrp	= ''	# Last shown proposal == lPrps[iPrp][1]
		
		self._clear()
		#def __init__
		
	def _clear(self):
		""" Clear for new session """
		self.sDoc	= ''
		self.pPrp	= -1
		self.sTx4Q	= ''
		self.lPrps	= None
		self.iPrp	= -1
		self.sPrp	= ''
		#def _clear
		
	def _checkAndUpd(self, findall=True):
		""" 
		Check situation.
		For start new session:
		- Is selection "poor" (only spaces)?
		- Is caret after word (if no selection)? 
		- Is next char suitable (no or space)?
		For continue:
		- If no stored proposals then start new session
		- If user change text or move caret|selection then start new session
		Return		'out'	- dont need any actions
					'cont'	- continue session (show proposals)
					'new'	- start new session 
		"""
		if ed.get_sel_mode() != sw.SEL_NORMAL:
			sw.msg_status(loctx('msg-only-normal'))
			return 'out'
		if ed.get_carets() is not None:
			sw.msg_status(loctx('msg-only-single'))
			return 'out'
		sDoc		= ed.get_text_all()
		pSel,nSel	= ed.get_sel()
		#pass;					LOG and log('self.sDoc==sDoc={}',(self.sDoc==sDoc))
		#pass;					LOG and log('0==nSel 0==self.nSel ={}',(0==nSel, 0==self.nSel))
		#pass;					LOG and log('self.pPrp + len(self.sPrp)==pSel={}',(self.pPrp + len(self.sPrp)==pSel))
		#pass;					LOG and log('self.pPrp==pSel self.nSel==nSel ={}',(self.pPrp==pSel, self.nSel==nSel))
		if	(	self.lPrps is not None 
			and 0!=len(self.lPrps)							# session 
			and	self.sDoc==sDoc		 						# text isnt changed
			and (	0==self.nSel 
					and 0==nSel 
					and self.pPrp + len(self.sPrp)==pSel 	# w/o sel mode and caret isnt changed
				or	0!=self.nSel 
					and self.pPrp==pSel
					and self.nSel==nSel						# with sel mode and selection isnt changed
				)
			):
			return 'cont'
		
		cAft		= sDoc[pSel+nSel]	if 1+pSel+nSel<len(sDoc)	else ' '
		if not cAft.isspace():
			sw.msg_status(loctx('msg-need-sp-sel' if 0!=nSel else 'msg-need-sp-crt'))
			return 'out'
		cBfr		= sDoc[pSel-1] 		if 0<pSel 					else ' '
		sUSel		= sDoc[pSel:pSel+nSel]
		if	(	0!=nSel and sUSel.isspace()
			or	0==nSel and (not re_test(self.CRE4WRD, cBfr)) 		and (not cBfr in self.CL4EXP)
			):
			sw.msg_status(loctx('msg-need-word-expr'))
			return 'out'
		
		# New session
		self._clear()
		self.sDoc		= sDoc
		if False:pass
		elif 0!=nSel:
			self.pPrp	= pSel
			self.nSel	= nSel
			self.sTx4Q	= sUSel
		else:
			self.nSel	= 0
			# Use prev word for start session
			sLine		= ed.get_text_line(ed.get_caret_xy()[1])
			sLine		= sLine[0:ed.get_caret_xy()[0]]
			if re_test(  self.CRE4WRD, cBfr):
				sLstWrd		= self.CRE4NWRD.split(sLine)[-1]	# rely: last char is RE4WRD
				pass;			LOG and log('sLstWrd, sLine={}',(sLstWrd, sLine))
				self.pPrp	= pSel-len(sLstWrd)
				self.sTx4Q	= sLstWrd
			else: # cBfr in self.CL4EXP
				sLstExpr	= re.split('\s', sLine)[-1]	# rely: last char not isspace()
				pass;			LOG and log('sLstExpr, sLine={}',(sLstExpr, sLine))
				self.pPrp	= pSel-len(sLstExpr)
				self.sTx4Q	= sLstExpr
		
		if findall:
			self._findall()
			if self.lPrps is None or 0==len(self.lPrps):
				sw.msg_status(loctx('msg-no-prps'))
				return 'out'
		return 'new'
		#def _checkAndUpd

	def _findall(self):
		cEnd		= self.sTx4Q[-1]
		sEsTx		= re.escape(self.sTx4Q)
		if 0:pass # cases
		elif re_test(  self.CRE4WRD, cEnd):
			# as word
			reQry	= re.compile(r'\b'+sEsTx+self.RE4WRD, re.I)		# '\b'=='\x08'!=r'\b' 	'\w'==r'\w'
		elif cEnd=='(':
			# as smth...)
			reQry	= re.compile(sEsTx+REOPCL_.replace('<', r'\(').replace('>', r'\)'), re.I)
		elif cEnd=='{':
			# as smth...}
			reQry	= re.compile(sEsTx+REOPCL_.replace('<',   '{').replace('>',   '}'), re.I)
		elif cEnd=='[':
			# as smth...]
			reQry	= re.compile(sEsTx+REOPCL_.replace('<', r'\[').replace('>', r'\]'), re.I)
		else:
			return
		itPrps		= map(lambda m:(m.start(), m.group()), reQry.finditer(self.sDoc))
		#pass;					LOG and log('itPrps={}',list(itPrps))
		itPrps		= filterfalse(lambda pp:pp[0]==self.pPrp, itPrps)		# skip start pos
		#pass;					LOG and log('itPrps={}',list(itPrps))
		itPrps		= unique_everseen(itPrps, lambda pp:pp[1])				# skip repeats
		#pass;					LOG and log('itPrps={}',list(itPrps))
		self.lPrps	= list(itPrps)
		if 0:pass # cases
		elif self.ORDER=='norm':pass
		elif self.ORDER=='up-dn':
			itUp	= filterfalse(lambda pp:pp[0]>self.pPrp, self.lPrps)
			itDn	= filterfalse(lambda pp:pp[0]<self.pPrp, self.lPrps)
			self.lPrps	= list(reversed(list(itUp)))+list(itDn)
		elif self.ORDER=='up':
			itUp	= filterfalse(lambda pp:pp[0]>self.pPrp, self.lPrps)
			self.lPrps	= list(reversed(list(itUp)))
		#pass;					LOG and log('self.lPrps={}',self.lPrps)
		#def _findall

	def wider(self):
		""" 
		Propose longer variant for start expr
		Example:				fun(0) fun| fun(0)[0]
			After first call:	fun(0) fun(0)| fun(0)[0]
			After second call:	fun(0) fun(0)[0]| fun(0)[0]
		Types of variants for smth:	
			smth(...) 
			smth=... 
			smth.chars
			smth,letters
			smth:{...}
			smth:[...]
			smth:'...'
			smth:"..."
		If selection is empty then started word is a word at left side of caret and variants will be shown without selection.
		Otherwize use selected text and will be shown selected variants.
		"""
		sHowDo		= self._checkAndUpd(findall=False)
		pass;					LOG and log('sHowDo={}',sHowDo)
		if sHowDo=='out':
			return
		if sHowDo=='cont':
			self.sTx4Q	= self.sPrp
			self.nSel	= 0 if 0==self.nSel else len(self.sTx4Q)

		sBsTx		= self.sTx4Q
		sEsTx		= re.escape(sBsTx)
		sQry		= None
		if 0:pass # cases
		elif sBsTx+'(' in self.sDoc:
			# smth(...) 
			sQry	= sEsTx + 			REOPCL.replace('<', r'\(').replace('>', r'\)')

		elif 	 re_test( sBsTx + r'\s*=',					self.sDoc, re.I):
			# smth=
			if 0:pass # cases
			elif re_test( sBsTx + r'\s*=\s*' + self.RE4WRD, self.sDoc, re.I):
				# smth=othr 
				sQry	= sEsTx + r'\s*=\s*' + self.RE4WRD 
			elif re_test( sBsTx + r"\s*=\s*'", 				self.sDoc, re.I):
				# smth='...' 
				sQry	= sEsTx + r"\s*=\s*'[^']*'" 
			elif re_test( sBsTx + r'\s*=\s*"', 				self.sDoc, re.I):
				# smth="..." 
				sQry	= sEsTx + r'\s*=\s*"[^"]*"' 
			elif re_test( sEsTx + r'\s*=\s*\(', self.sDoc, re.I):
				# smth=(...) 
				sQry	= sEsTx + r'\s*=\s*' +	REOPCL.replace('<', r'\(').replace('>', r'\)')
			elif re_test( sEsTx + r'\s*=\s*\[', 			self.sDoc, re.I):
				# smth=[...] 
				sQry	= sEsTx + r'\s*=\s*' +	REOPCL.replace('<', r'\[').replace('>', r'\]')
			elif re_test( sEsTx + r'\s*=\s*\{', 			self.sDoc, re.I):
				# smth={...} 
				sQry	= sEsTx + r'\s*=\s*' +	REOPCL.replace('<', r'\{').replace('>', r'\}')

		elif sBsTx+':' in self.sDoc:
			# smth:
			if 0:pass # cases
			elif re_test( sEsTx + r":\s*'", 				self.sDoc, re.I):
				# smth: '...' 
				sQry	= sEsTx +							r":\s*'[^']*'"
			elif re_test( sEsTx + r':\s*"', 				self.sDoc, re.I):
				# smth: "..." 
				sQry	= sEsTx +	 						r':\s*"[^"]*"'
			elif re_test( sEsTx + r':\s*\(', 				self.sDoc, re.I):
				# smth: (...) 
				sQry	= sEsTx + r':\s*' +	REOPCL.replace('<', r'\(').replace('>', r'\)')
			elif re_test( sEsTx + r':\s*\[', 				self.sDoc, re.I):
				# smth: [...] 
				sQry	= sEsTx + r':\s*' +	REOPCL.replace('<', r'\[').replace('>', r'\]')
			elif re_test( sEsTx + r':\s*\{', 				self.sDoc, re.I):
				# smth: {...} 
				sQry	= sEsTx + r':\s*' +	REOPCL.replace('<', r'\{').replace('>', r'\}')

		elif ':'==sBsTx[-1]:
			# smth:
			if 0:pass # cases
			elif re_test( sEsTx + r"\s*'", 					self.sDoc, re.I):
				# smth'...' 
				sQry	= sEsTx +							r"\s*'[^']*'"
			elif re_test( sEsTx + r'\s*"					', self.sDoc, re.I):
				# smth"..." 
				sQry	= sEsTx + 							r'\s*"[^"]*"'
			elif re_test( sEsTx + r'\s*\(', 				self.sDoc, re.I):
				# smth(...) 
				sQry	= sEsTx + r'\s*' +	REOPCL.replace('<', r'\(').replace('>', r'\)')
			elif re_test( sEsTx + r'\s*\[', 				self.sDoc, re.I):
				# smth[...] 
				sQry	= sEsTx + r'\s*' +	REOPCL.replace('<', r'\[').replace('>', r'\]')
			elif re_test( sEsTx + r'\s*\{', 				self.sDoc, re.I):
				# smth{...} 
				sQry	= sEsTx + r'\s*' +	REOPCL.replace('<', r'\{').replace('>', r'\}')

		if sQry	is None:
			sw.msg_status(loctx('msg-no-prps'))
			return

		reQry		= re.compile(sQry, re.I)
		itPrps		= map(lambda m:(m.start(), m.group()), reQry.finditer(self.sDoc))
		itPrps		= filterfalse(lambda pp:pp[0]==self.pPrp, itPrps)		# skip start pos
		itPrps		= unique_everseen(itPrps, lambda pp:pp[1])				# skip repeats
		self.lPrps	= list(itPrps)
		if 0:pass # cases
		elif self.ORDER=='norm':pass
		elif self.ORDER=='up-dn':
			itUp	= filterfalse(lambda pp:pp[0]>self.pPrp, self.lPrps)
			itDn	= filterfalse(lambda pp:pp[0]<self.pPrp, self.lPrps)
			self.lPrps	= list(reversed(list(itUp)))+list(itDn)
		elif self.ORDER=='up':
			itUp	= filterfalse(lambda pp:pp[0]>self.pPrp, self.lPrps)
			self.lPrps	= list(reversed(list(itUp)))
		if 0==len(self.lPrps):
			sw.msg_status(loctx('msg-no-prps'))
			return
		self._setPrp(0)
		#def wider

	def config(self):
		l		= '\n'
		what	= sw.dlg_menu(sw.MENU_STD, '', '\n'.join([
					 icase(self.ORDER=='norm',	'?','')+loctx('cfgm-order-norm')	# 0
					,icase(self.ORDER=='up-dn',	'?','')+loctx('cfgm-order-up-dn')	# 1
					,icase(self.ORDER=='up',	'?','')+loctx('cfgm-order-up')		# 2
					,'-'
					,icase(self.WRAP, '!', '')+loctx('cfgm-wrap')					# 4
					,icase(self.VIEW_LNM, '!', '')+loctx('cfgm-nm-lnm')				# 5
					,loctx('cfgm-ext-wrd').format(self._C4WRD)						# 6 
					,icase(self.VIEW_TYPE=='dlg','*','')
					+loctx('cfgm-mn-block').format(int(self.MENU_MAX/4))			# 7 
					,'-'
					,icase(self.VIEW_TYPE=='pop','?','')+loctx('cfgm-nm-pop')		# 9
					,icase(self.VIEW_TYPE=='dlg','?','')+loctx('cfgm-nm-dlg')		# 10
					,icase(self.VIEW_TYPE=='mix','?','')+loctx('cfgm-nm-mix')		# 11
					]))
		pass;					LOG and log('what={}'.format(what))
		if 0:pass # cases
		elif -1==what or None==what:
			return
		elif 0==what:
			self.ORDER	='norm'
		elif 1==what:
			self.ORDER	='up-dn'
		elif 2==what:
			self.ORDER	='up'
		elif 4==what:
			self.WRAP	= not self.WRAP
		elif 5==what:
			self.VIEW_LNM	= not self.VIEW_LNM
		elif 6==what:
			sExtra	= sw.dlg_input(loctx('cfgi-ext-wrd'), self._C4WRD, '', '')
			if sExtra is None: return
			self._C4WRD		= sExtra
			self.RE4WRD		= r'[\w' +re.escape(self._C4WRD)+']+'	# Chars are used for complete the word
			self.RE4NWRD	= r'[^\w'+re.escape(self._C4WRD)+']+'	# Chars are used for locate a word
			self.CRE4WRD	= re.compile(self.RE4WRD)
			self.CRE4NWRD	= re.compile(self.RE4NWRD)
		elif 7==what:
			sMnGrd	= sw.dlg_input(loctx('cfgi-mn-block'),  str(int(self.MENU_MAX/4)), '', '')
			if sMnGrd is None: return
			pass;				LOG and log('sMnGrd={}',(sMnGrd))
			nMnGrd	= max(1, min(5, int(sMnGrd)))
			self.MENU_MAX	= 4*nMnGrd
		elif 9==what:
			self.VIEW_TYPE	='pop'
		elif 10==what:
			self.VIEW_TYPE	='dlg'
		elif 11==what:
			self.VIEW_TYPE	='mix'

		ini_write('view-type',	self.VIEW_TYPE)
		ini_write('view-lnm',	self.VIEW_LNM)
		ini_write('menu-max',	self.MENU_MAX)
		ini_write('order',		self.ORDER)
		ini_write('wrap', 		self.WRAP)
		ini_write('extra', 		self._C4WRD)
		#def config

	def view(self):
		""" 
		Show all proposals in local menu.
		"""
		sHowDo		= self._checkAndUpd()
		pass;					LOG and log('sHowDo={}',sHowDo)
		if sHowDo=='out':	return

		iPrp	= -1
		if 0:pass
		elif self.VIEW_TYPE=='dlg' or self.VIEW_TYPE=='mix' and len(self.lPrps)>self.MENU_MAX:
			lMns	= [ ( '{}. '.format(1+ips[0])
						 +('({}) '.format(1+ed.pos_xy(ips[1][0])[1]) if self.VIEW_LNM else '')
						, ips[0]
						, ips[1][1].translate(str.maketrans(chr(9)+chr(10)+chr(13), '   ')) )
						for ips in enumerate(self.lPrps) ]
			what	= sw.dlg_menu(sw.MENU_SIMPLE, '({}) {}'.format(len(self.lPrps), self.sTx4Q), '\n'.join(
						['{}{}{}'.format(ips[2], chr(9), ips[0]) for ips in lMns]
						))
			#pass;					log('what={}'.format(what))
			if 0:pass # cases
			elif -1==what or None==what:
				return
			iPrp	= lMns[what][1]
		elif self.VIEW_TYPE=='pop' or self.VIEW_TYPE=='mix' and len(self.lPrps)<=self.MENU_MAX:
			""" If count of proposals is big then menu will have only
				  some topmost 
				* some nearest around insert point
				  some nearest around last
				! last proposed
				  some lowermost """
			nIts	= int(self.MENU_MAX/4)
			nNear	= min(enumerate(self.lPrps), key=lambda npp:abs(npp[1][0] - self.pPrp))[0]
#			lMns	= [ ( icase(ips[0]==self.iPrp, '!', abs(ips[0]-nNear)<nIts, '?', '')
			lMns	= [ ( icase(ips[0]==self.iPrp, '!', 							 '')
						, '{}. '.format(1+ips[0])
						 +('({}) '.format(1+ed.pos_xy(ips[1][0])[1]) if self.VIEW_LNM else '')
						, ips[0]
						, ips[1][1].translate(str.maketrans(chr(9)+chr(10)+chr(13), '   ')) )
						for ips in enumerate(self.lPrps)
						if ips[0]<nIts
						or ips[0]>=len(self.lPrps)-nIts
						or abs(ips[0]-self.iPrp)<nIts
						or abs(ips[0]-nNear)	<nIts
					  ]
			for i in range(len(lMns)-2,2,-1):
				if lMns[i][2] - lMns[i-1][2] > 1:
					lMns.insert(i, ('-', '', 0, ''))
			#pass;					LOG and log('lMns={}',lMns)
			what	= sw.dlg_menu(sw.MENU_STD, '', '\n'.join(
						['{}{}{}'.format(sips[0], sips[1], sips[3]) for sips in lMns]
						))
			#pass;					log('what={}'.format(what))
			if 0:pass # cases
			elif -1==what or None==what or lMns[what][0]=='-' or lMns[what][0]=='!':
				return
			iPrp	= lMns[what][2]
			#pass;					LOG and log('it {}',self.lPrps[iPrp])
		self._setPrp(iPrp)
		#def view
		
	def next(self):
		""" 
		Propose top|next variant for start word|expr.
		Word example:			str11 st| str22
			After first call:	str11 str11| str22
			After second call:	str11 str22| str22
		Expr example:			fun(11) fun(| fun(22,'')
			After first call:	fun(11) fun(11)| fun(22,'')
			After second call:	fun(22) fun(22,'')| fun(22,'')
		Word-chars include . _ 
		Types of parsed expr:
			started: smth(		completed: smth(...)		ex: fun(   o.meth(   key:(
			started: smth:[		completed: smth:[...]		ex: key:[
			started: smth:{		completed: smth:{...}		ex: key:{
			started: smth:'		completed: smth:'...'		ex: key:' 
			started: smth:"		completed: smth:"..."		ex: key:" 
		If selection is empty then started word is a word at left side of caret and variants will be shown without selection.
		Otherwize use selected text and will be shown selected variants.
		"""
		sHowDo		= self._checkAndUpd()
		pass;					LOG and log('sHowDo={}',sHowDo)
		if sHowDo=='out':		return
		return self._same('next')
		# def next
	def prev(self):
		""" 
		Propose bottom|prev variant for start word|expr
		Word example:			str11 st| str22
			After first call:	str11 str22| str22
			After second call:	str11 str11| str22
		See more in doc for next(self)
		"""
		sHowDo		= self._checkAndUpd()
		pass;					LOG and log('sHowDo={}',sHowDo)
		if sHowDo=='out':		return
		return self._same('prev')
		# def prev
		
	def _setPrp(self, iPrp):
		""" View proposal with index iPrp """
		pass;					LOG and log('iPrp={}',(iPrp))
		nOld		= icase(''!=self.sPrp, len(self.sPrp), len(self.sTx4Q))		# Rely sTx4Q for start
		self.iPrp	= iPrp
		nShft4Pos	= self.lPrps[iPrp][0] - nOld
		self.lPrps	= list(map(lambda pp: pp if pp[0]<=self.pPrp else (nShft4Pos+pp[0], pp[1]), self.lPrps)) 
		self.sPrp	= self.lPrps[iPrp][1]
		ed.replace(self.pPrp, nOld, self.sPrp)
		if 0!=self.nSel:
			set_sel(ed,		 self.pPrp,	 len(self.sPrp))
			self.nSel= len(self.sPrp)
		else:
			ed.set_caret_pos(self.pPrp + len(self.sPrp))
		self.sDoc	= ed.get_text_all()
		if self.VIEW_LNM:
			sw.msg_status('({}/{})[{}] "{}"'.format(1+iPrp, len(self.lPrps), 1+ed.pos_xy(self.lPrps[iPrp][0])[1], self.sTx4Q))
		else:
			sw.msg_status('({}/{}) "{}"'.format(	1+iPrp, len(self.lPrps), 									  self.sTx4Q))
		#def _setPrp

	def _same(self, sNxPr):
		""" sNxPr 		in ('next', 'prev')	"""
		pass;					LOG and log('sNxPr={}',(sNxPr))
		# Continue from last propose
		nDir	= icase(sNxPr=='next', 1, -1)
		iPrp	= nDir + self.iPrp
		iPrp	= icase(-2==iPrp, -1, iPrp)
		#pass;					LOG and log('iPrp={}',(iPrp))
		iPrp	= icase(self.WRAP, iPrp % len(self.lPrps), iPrp)
		#pass;					LOG and log('iPrp={}',(iPrp))
		if	not 0<=iPrp<len(self.lPrps):
			#pass;			LOG and log('CONT {} no more',sNxPr)
			return sw.msg_status(loctx('msg-no-more'))
		self._setPrp(iPrp)
		#def _same
	
	#class Command

######################################
## Syb Py-API helpers
######################################
def loctx(id, deftx=''):
	tx	= sw.text_local(id, __file__)
	return deftx if ''==tx else tx
	# def loctx

def ini_read(key, dfval):
	sval	= sw.ini_read(INI_FILE, INI_SEC, key, str(dfval))
	if 0:pass # cases
	elif type(dfval) is type(True):
		return sval==str(True)
	elif type(dfval) is type(1):
		return int(sval)
	elif type(dfval) is type(1.1):
		return float(sval)
	else:
		return sval
	# def ini_read
def ini_write(key, val):
	sw.ini_write(INI_FILE, INI_SEC, key, str(val))
	# def ini_write

def lock_syn(bLock, ed4=None):
	if ed4!=None: 
		if bLock: 
			ed4.lock()
		else:
			ed4.unlock()
	if '1.0.122'>=sw.app_api_version()>='1.0.119': 
		return sw.app_lock(sw.LOCK_STATUS		if bLock else sw.UNLOCK_STATUS)
	if 			  sw.app_api_version()>='1.0.123': 
		return sw.app_proc(sw.PROC_LOCK_STATUS	if bLock else sw.PROC_UNLOCK_STATUS)
	# lock_syn
	
def set_sel(edSW, pBgn, nLen, bRever=False):
	""" Bugfix for sw.ed.set_sel(start, len, nomove=False)
		bug-1: http://synwrite.sourceforge.net/forums/viewtopic.php?p=5311#p5311
		bug-2: http://synwrite.sourceforge.net/forums/viewtopic.php?p=5313#p5313
	"""
	pOldCrt	= edSW.get_caret_pos()
	#pass;						LOG and log('>>pOldCrt={}, pBgn, nLen, bRever={}',pOldCrt,(pBgn, nLen, bRever))
	if bRever:
		# 1. Reverse selection
		#pass;					LOG and log('REV')
		lock_syn(True, edSW)
		edSW.set_caret_pos(pBgn+nLen)
		for step in range(nLen):
			edSW.cmd(cmd_SelLeft, '')	# 1 or 2 chars selected (2 = CRLF) 
			if pBgn==edSW.get_caret_pos():
				break
		lock_syn(False, edSW)
	else:
		if pOldCrt==pBgn and nLen>0:
			# 2. Direct selection from caret
			#pass;				LOG and log('DIR')
			edSW.set_caret_pos(1+pBgn)	# Hack! Move caret to any pos!=pOldCrt 
		edSW.set_sel(pBgn, nLen) 
	#pass;						LOG and log('<<get_caret_pos()={}',(edSW.get_caret_pos()))
	#def set_sel

######################################
## Py helpers
######################################
def re_test(pattern, string, flags=0):
	# Testing for one matching
	if type(pattern) is type(''):
		for it in re.finditer(pattern, string, flags):
			return True
	else:
		for it in pattern.finditer(string):
			return True
	return False
	# def re_test

def log(msg='', *args):
	""" 
	en:
		Light print-logger. Commands are included into msg:  
			>> << {{	Expand/Narrow/Cancel gap 
		Execute msg.format(*args).  So you can insert Format String Syntax into msg.
		Replace '¬' to chr(9), '¶'to chr(13).
	ru:
		Легкий pring-логгер. Управляющие команды внутри msg:
			>> << {{	Увеличить/Уменьшить/Отменить отступ 
		Выполняет msg.format(*args). Поэтому в msg можно использовать Format String Syntax.
		Заменяет '¬' на chr(9), '¶'на chr(13).

		Example.
		1	class C:
		2		def m(): 
		3			log('qwerty') 
		4			log('>>more gap here') 
		5			log('v1={}¶v2,v3¬{}',12,('ab',{})) 
		6			log('<<less gap at next') 
		7			log('QWERTY') 
		output 
			C.m:3 qwerty
				C.m:4 >>more gap here
				C.m:5 v1=12
			v2,v3	('ab', {}) 
				C.m:6 <<less gap at next
			C.m:7 QWERTY
	"""
	global log_gap
	lctn	= ''
	if -1==-1: # add "location"
		frCaller= inspect.stack()[1]	# 0-log, 1-need func
		try:
			cls	= frCaller[0].f_locals['self'].__class__.__name__ + '.'
		except:
			cls	= ''
		fun,ln	= (cls + frCaller[3]).replace('.__init__','()'), frCaller[2]
		lctn	= '{}:{} '.format(fun, ln)

	if 0<len(args):
		msg	= msg.format(*args) 
	log_gap = log_gap + (chr(9) if '>>' in msg else '')
	msg		= log_gap + lctn + msg.replace('¬',chr(9)).replace('¶',chr(10))
		
	print(msg)
	
	log_gap = icase('<<' in msg, log_gap[:-1]
				,	'{{' in msg, ''
				,				 log_gap )
	#def log

def icase(*pars):
	""" 
	en:
		Params	cond1,val1[, cond2,val2, ...[, valElse]...] 
		Result	Value for first true cond in pairs otherwise last odd param or None
	ru:
		Параметры	усл-1,знач-1[, усл-2,знач-2, ...[, знач-Иначе]...]
		Результат	Первое значение, для которого есть парное истинное условие. 
					Иначе последний нечетный параметр, а если его нет, то None
		Examples
			icase(1==2,'a', 3==3,'b') == 'b'
			icase(1==2,'a', 3==4,'b', 'c') == 'c'
			icase(1==2,'a', 3==4,'b') == None
	"""
	for ppos in range(1,len(pars),2) :
		if pars[ppos-1] :
			return pars[ppos]
	return pars[-1] if 1==len(pars)%2 else None
	#def icase

#######################################################
def unique_everseen(iterable, key=None):
    """
	List unique elements, preserving order. Remember all elements ever seen.
    # unique_everseen('AAAABBBCCDAABBB') --> A B C D
    # unique_everseen('ABBCcAD', str.lower) --> A B C D
	"""
    seen = set()
    seen_add = seen.add
    if key is None:
        for element in filterfalse(seen.__contains__, iterable):
            seen_add(element)
            yield element
    else:
        for element in iterable:
            k = key(element)
            if k not in seen:
                seen_add(k)
                yield element

#######################################################
if __name__ == '__main__':
	pass;						print('OK')
