#! /usr/bin/env python3
# coding: cp1251

# Author: Andrey Kvichansky	<kvichans@mail.ru>
# Revision:	0.82
# Last modification: 27 mar 2014

import	sw 
from 	sw 		import ed
from 	sw_cmd	import *	# cmd_SelLeft

import re

# Logging
import inspect	# stack
LOG		= False	# Do or dont logging
log_gap	= ''	# used only into log()

mOpBrs	= 	{	'(':')'
			,	'[':']'
			,	'{':'}'
			,	'<':'>'
			,	'‹':'›'
			,	'«':'»'
			}
mPairs	= mOpBrs.copy()
mPairs.update({cCl:cOp for cOp,cCl in mOpBrs.items()})

class Command:
	SIGNS		= r'-\+=!@#$%^&*/;:.,'	#+'"'+"'" 	  #+'"'+"'"

	def __init__(self):
		self.reAlNms	= None
		self.reSigns	= None
		self.reBln		= None
		self.reELn		= None
		self.reLin		= None
		self.reLne		= None
		
		self.bCopy		= False
		#def __init__
		
	def menu(self):
		sAble	= icase(self.bCopy,'*','')
		what	= sw.dlg_menu(sw.MENU_STD, ''
				, '\n'.join(
				(	sAble+	'&Expand sel'			+chr(9)+"Ctrl+'"		# 0
				,	sAble+	'Sh&rink sel'									# 1
				,	'-'
				,			'Ex&pand sel and copy'	+chr(9)+"Shift+Ctrl+'"	# 3
				,			'Shr&ink sel and copy'							# 4
				,	'-'
				,	'{}A&uto copy'.format(icase(self.bCopy, '!', ''))		# 6
				)))
		#pass;					sw.msg_status('what={}'.format(what))
		if 0:pass # cases
		elif 0==what:
			self.expand(self.bCopy)
		elif 1==what:
			self.narrow(self.bCopy)
		elif 3==what and not self.bCopy:
			self.expand(True)
		elif 4==what and not self.bCopy:
			self.narrow(True)
		elif 6==what or 3==what and self.bCopy:
			self.bCopy	= not self.bCopy
		# def menu
		
	def expandAndCopy(self):
		self.expand(True)

	def expand(self, bCopy=False):
		""" SynWrite plugin.
		en:	
		Expand selection to the nearest usefull state:
			caret - word - phrase in brakets - phrase with brakets - ...
		Params
		bCopy	Copy new (only new) selected text to clipboard
		Return	Selection is changed
		ru: 
		Расширяет текущее выделение до ближайшего логически полезного состояния.
			каретка - слово - фраза до синт.знаков - фраза с синт.знаками - фраза в скобках - фраза со скобками - ..
		Параметры
		bCopy	Копировать измененный (только измененный) выделенный текст в буфер обмена
		Возврат	Выделение изменилось

		Example. | caret, <...> selection
			fun('smt an|d oth', par)
			fun('smt <and> oth', par)
			fun('<smt and oth>', par)
			fun(<'smt and oth'>, par)
			fun(<'smt and oth', par>)
			fun<('smt and oth', par)>
			<fun('smt and oth', par)>
		"""	
		if self._expandOnly() and bCopy:
			set_clip(ed.get_text_sel())

	def _expandOnly(self):
		pass;					global LOG
		if ed.get_sel_mode() != sw.SEL_NORMAL:
			sw.msg_status('expand: FAIL. Only for Normal-mode of selection')
			return False
			
		cAP,cQT		= "'", '"'	# "'", '"'
             
		(pSelBgn
		,nSelLen)	= ed.get_sel()
		sText		= ed.get_text_all()
		if nSelLen==len(sText):
			return False
		bCrtAtBgn	= 0<nSelLen and ed.get_caret_pos()==pSelBgn 
		bCrtAtEnd	= 				ed.get_caret_pos()==pSelBgn+nSelLen 
		sSel		= sText[pSelBgn:pSelBgn+nSelLen]
		cBfr1		= '' if pSelBgn		   ==0			else sText[pSelBgn-1]
		cAft1		= '' if pSelBgn+nSelLen==len(sText) else sText[pSelBgn+nSelLen] 
		#pass;					LOG and log('len(sText),sText={}',(len(sText),sText))
		pass;					LOG and log('pSelBgn,nSelLen={}',(pSelBgn,nSelLen))
		pass;					LOG and log('cBfr1,cAft1={}',(cBfr1,cAft1))

		if	(	mOpBrs.get(cBfr1)==cAft1  and sSel.count(cBfr1)==sSel.count(cAft1)
			or	cBfr1==cAP and cAft1==cAP and sSel.count(cAP)%2==0
			or	cBfr1==cQT and cAft1==cQT and sSel.count(cQT)%2==0 
			):
			pass;				LOG and log('(SEL)')
			set_sel(ed,pSelBgn-1, nSelLen+2, bCrtAtBgn)
#			ed.set_sel(pSelBgn-1, nSelLen+2, bCrtAtBgn) 
			return True
		
		sAftTx		= sText[  pSelBgn+nSelLen:]
		#pass;					LOG and log('sAftTx={}',(sAftTx))
		sBfrTx		= None	# ''.join(reversed(sText[0:pSelBgn]))	# NB! slowly on big text
		#pass;					LOG and log('sBfrTx={}',(sBfrTx))
		(nBfrGap
		,nAftGap)	= 0, 0

		if	self.reAlNms is None:
			self.reAlNms = re.compile(r'^\w+')
		if	cBfr1.isalnum() or cBfr1=='_' or cAft1.isalnum() or cAft1=='_':
			# Expand to word
			if cBfr1.isalnum() or cBfr1=='_':
				if sBfrTx is None:	sBfrTx = ''.join(reversed(sText[0:pSelBgn]))	# NB! slowly on big text
				nBfrGap	= len(self.reAlNms.search(sBfrTx).group())	# Rely: isalnum ~ reAlNms  
			if cAft1.isalnum() or cAft1=='_':
				nAftGap	= len(self.reAlNms.search(sAftTx).group())	# Rely: isalnum ~ reAlNms
			pass;				LOG and log('ISALNUM nBfrGap,nAftGap={}',(nBfrGap,nAftGap))
			set_sel(ed,pSelBgn-nBfrGap, nSelLen+nBfrGap+nAftGap, bCrtAtBgn) 
#			ed.set_sel(pSelBgn-nBfrGap, nSelLen+nBfrGap+nAftGap, bCrtAtBgn) 
			return True

		for cOp,cCl in mOpBrs.items():
			if not ((cBfr1==cOp or cAft1==cCl) and sSel.count(cOp)==sSel.count(cCl)): continue
			# Expand to select all into (...) or [...] or ...
			if cBfr1==cOp:
				nAftGap	= findOfNotPair(sAftTx, cCl)
			if cAft1==cCl:
				if sBfrTx is None:	sBfrTx = ''.join(reversed(sText[0:pSelBgn]))	# NB! slowly on big text
				nBfrGap	= findOfNotPair(sBfrTx, cOp) 
			pass;				LOG and log('(EXT) nBfrGap,nAftGap={}',(nBfrGap,nAftGap))
			if nBfrGap!=-1 and nAftGap!=-1:
				set_sel(ed,pSelBgn-nBfrGap, nSelLen+nBfrGap+nAftGap, bCrtAtBgn)
#				ed.set_sel(pSelBgn-nBfrGap, nSelLen+nBfrGap+nAftGap, bCrtAtBgn)
				return True 

		for cOp,cCl in mOpBrs.items():
			if cAft1==cOp:
				# Expand to select up to next ")"
				nAftGap	= findOfNotPair(sAftTx[1:], cCl)
				pass;			LOG and log('SEL(? nAftGap={}',(nAftGap))
				if nAftGap!=-1:
					set_sel(ed,pSelBgn, nSelLen+nAftGap+2, bCrtAtBgn)
#					ed.set_sel(pSelBgn, nSelLen+nAftGap+2, bCrtAtBgn)
					return True 

		for cOp,cCl in mOpBrs.items():
			if cBfr1==cCl:
				# Expand to select up to prev "("
				if sBfrTx is None:	sBfrTx = ''.join(reversed(sText[0:pSelBgn]))	# NB! slowly on big text
				nBfrGap	= findOfNotPair(sBfrTx[1:], cOp)
				pass;			LOG and log('?)SEL nBfrGap={}',(nBfrGap))
				if nBfrGap!=-1:
					set_sel(ed,pSelBgn-nBfrGap-2, nSelLen+nBfrGap+2, bCrtAtBgn)
#					ed.set_sel(pSelBgn-nBfrGap-2, nSelLen+nBfrGap+2, bCrtAtBgn)
					return True 

		if	(	cBfr1==cQT and sSel.count(cQT)%2==0 
			or	cBfr1==cAP and sSel.count(cAP)%2==0 ):
			cWt	= icase(cBfr1==cQT, cQT, cAP)
			if sBfrTx is None:	sBfrTx = ''.join(reversed(sText[0:pSelBgn]))	# NB! slowly on big text
			if 0:pass
			elif sBfrTx.count(cWt)%2==0:
				# Expand to select up to prev quota
				nBfrGap	= sBfrTx[1:].find(cWt)
				pass;			LOG and log('...{}SEL nBfrGap={}',cWt,nBfrGap)
				if nBfrGap!=-1:
					set_sel(ed,pSelBgn-nBfrGap-2, nSelLen+nBfrGap+2, bCrtAtBgn)
#					ed.set_sel(pSelBgn-nBfrGap-2, nSelLen+nBfrGap+2, bCrtAtBgn)
					return True 
			elif sAftTx.count(cWt)%2==1:
				# Expand to select all into cWt...cWt
				nAftGap	= sAftTx[1:].find(cWt)
				pass;			LOG and log('{}SEL... nAftGap={}',cWt,nAftGap)
				if nAftGap!=-1:
					set_sel(ed,pSelBgn, nSelLen+nAftGap+1, bCrtAtBgn)
#					ed.set_sel(pSelBgn, nSelLen+nAftGap+1, bCrtAtBgn)
					return True 

		if	(	cAft1==cQT and sSel.count(cQT)%2==0 
			or	cAft1==cAP and sSel.count(cAP)%2==0 ):
			cWt	= icase(cAft1==cQT, cQT, cAP)
			if sBfrTx is None:	sBfrTx = ''.join(reversed(sText[0:pSelBgn]))	# NB! slowly on big text
			if 0:pass
			elif sAftTx.count(cWt)%2==0:
				# Expand to select up to prev quota
				nAftGap	= sAftTx[1:].find(cWt)
				pass;			LOG and log('SEL{}... nAftGap={}',cWt,nAftGap)
				if nAftGap!=-1:
					set_sel(ed,pSelBgn, nSelLen+nAftGap+2, bCrtAtBgn)
#					ed.set_sel(pSelBgn, nSelLen+nAftGap+2, bCrtAtBgn)
					return True 
			elif sBfrTx.count(cWt)%2==1:
				# Expand to select all into cWt...cWt
				nBfrGap	= sBfrTx[1:].find(cWt)
				pass;			LOG and log('...SEL{} nBfrGap={}',cWt,nBfrGap)
				if nBfrGap!=-1:
					set_sel(ed,pSelBgn-nBfrGap-1, nSelLen+nBfrGap+1, bCrtAtBgn)
#					ed.set_sel(pSelBgn-nBfrGap-1, nSelLen+nBfrGap+1, bCrtAtBgn)
					return True 
		
		if	self.reSigns is None:
			self.reSigns = re.compile('^[^\w\s'+re.escape(cAP+cQT+'({[<>]})')+']+')
		if (	self.reSigns.match(cBfr1)
			or  self.reSigns.match(cAft1) ):
			# Expand with signs
			pass;				LOG and log('SIGNS')
			if self.reSigns.match(cBfr1):
				if sBfrTx is None:	sBfrTx = ''.join(reversed(sText[0:pSelBgn]))	# NB! slowly on big text
				nBfrGap	= len(self.reSigns.search(sBfrTx).group())
			if self.reSigns.match(cAft1):
				nAftGap	= len(self.reSigns.search(sAftTx).group())
			set_sel(ed,pSelBgn-nBfrGap, nSelLen+nBfrGap+nAftGap, bCrtAtBgn) 
#			ed.set_sel(pSelBgn-nBfrGap, nSelLen+nBfrGap+nAftGap, bCrtAtBgn) 
			return True

		sBln	= ' '+chr(9)
		if	self.reBln is None:
			self.reBln = re.compile(r'^['+re.escape(sBln)+']+')
		if	(	cBfr1!='' and cBfr1 in sBln 
			or	cAft1!='' and cAft1 in sBln ):
			# Expand with blanks
			if cBfr1!='' and cBfr1 in sBln:
				if sBfrTx is None:	sBfrTx = ''.join(reversed(sText[0:pSelBgn]))	# NB! slowly on big text
				nBfrGap	= len(self.reBln.search(sBfrTx).group())
			if cAft1!='' and cAft1 in sBln:
				nAftGap	= len(self.reBln.search(sAftTx).group())
			pass;				LOG and log('BLN nBfrGap,nAftGap={}',(nBfrGap,nAftGap))
			set_sel(ed,pSelBgn-nBfrGap, nSelLen+nBfrGap+nAftGap, bCrtAtBgn) 
#			ed.set_sel(pSelBgn-nBfrGap, nSelLen+nBfrGap+nAftGap, bCrtAtBgn) 
			return True

		sEol	= chr(10)+chr(13)
		if	self.reELn is None:
			sEscEol		= re.escape(sEol)
			self.reELn	= re.compile(r'^['+sEscEol+']+[^'+sEscEol+']*')
			self.reLin	= re.compile(r'^[^'+sEscEol+']+')
			self.reLne	= re.compile(r'^[^'+sEscEol+']*['+sEscEol+']*')
		if	(	cBfr1!='' and cBfr1 	in sEol
		 	and	cAft1!='' and cAft1 not in sEol ):
			# Expand to whole line with last EOL
			pass;				LOG and log('eolSEL?')
			nAftGap	= len(self.reLne.search(sAftTx).group())
			pass;				LOG and log('nAftGap={}',(nAftGap))
			set_sel(ed,pSelBgn, nSelLen+nAftGap, bCrtAtBgn) 
#			ed.set_sel(pSelBgn, nSelLen+nAftGap, bCrtAtBgn) 
			return True
		if	(	cAft1!='' and cAft1 	in sEol 
			and	cBfr1!='' and cBfr1 not in sEol ):
			# Expand to whole line without first EOL
			# Expand with EOLs
			if sBfrTx is None:	sBfrTx = ''.join(reversed(sText[0:pSelBgn]))	# NB! slowly on big text
			nBfrGap	= len(self.reLin.search(sBfrTx).group())
			pass;				LOG and log('?SELeol nBfrGap={}',(nBfrGap))
			set_sel(ed,pSelBgn-nBfrGap, nSelLen+nBfrGap, bCrtAtBgn) 
#			ed.set_sel(pSelBgn-nBfrGap, nSelLen+nBfrGap, bCrtAtBgn) 
			return True
		if	(	cBfr1!='' and cBfr1 in sEol 
			or	cAft1!='' and cAft1 in sEol ):
			# Expand with EOLs
			if cBfr1!='' and cBfr1 in sEol:
				if sBfrTx is None:	sBfrTx = ''.join(reversed(sText[0:pSelBgn]))	# NB! slowly on big text
				nBfrGap	= len(self.reELn.search(sBfrTx).group())
			if cAft1!='' and cAft1 in sEol:
				nAftGap	= len(self.reELn.search(sAftTx).group())
			pass;				LOG and log('?eolSELeol? nBfrGap,nAftGap={}',(nBfrGap,nAftGap))
			set_sel(ed,pSelBgn-nBfrGap, nSelLen+nBfrGap+nAftGap, bCrtAtBgn) 
#			ed.set_sel(pSelBgn-nBfrGap, nSelLen+nBfrGap+nAftGap, bCrtAtBgn) 
			return True

		return False
		#def _expandOnly
 
	def narrowAndCopy(self):
		self.narrow(True)

	def narrow(self, bCopy=False):
		""" SynWrite plugin.
			en:	Narrow selection to the nearest usefull state.
				bCopy	Copy new (only new) selected text to clipboard
				Return	Selection is changed
			ru: Сужает текущее выделение до ближайшего логически полезного состояния.
				bCopy	Копировать измененный (только измененный) выделенный текст в буфер обмена
				Возврат	Выделение изменилось
		"""
		if self._narrowOnly() and bCopy:
			set_clip(ed.get_text_sel())

	def _narrowOnly(self):
		if ed.get_sel_mode() != sw.SEL_NORMAL:
			sw.msg_status('narrow: FAIL. Only for Normal-mode of selection')
			return False
		(pSelBgn
		,nSelLen)	= ed.get_sel()
		if 0 == nSelLen:
			return False

		cAP,cQT		= "'", '"'	# "'", '"'	
             
		bCrtAtBgn	= 0<nSelLen and ed.get_caret_pos()==pSelBgn 
		bCrtAtEnd	= 				ed.get_caret_pos()==pSelBgn+nSelLen 
		sSel		= ed.get_text_substr(pSelBgn, nSelLen)
		pass;					LOG and log('bCrtAtBgn,bCrtAtEnd,sSel={}',(bCrtAtBgn,bCrtAtEnd,sSel))

		cFst, cLst	= sSel[0], sSel[-1]
		sInSel		= sSel[1:-1]
		pass;					LOG and log('cFst, cLst={}',(cFst, cLst))

		if (	mOpBrs.get(cFst)==cLst  
				and sInSel.count(cFst)==sInSel.count(cLst)
				and (	sInSel.count(cFst)==0 
					or	findOfNotPair(sSel[1:],cLst)==nSelLen-1-1 )	# cFst-cLst is pair
			or	cFst==cAP and cLst==cAP and cAP not in sInSel
			or	cFst==cQT and cLst==cQT and cQT not in sInSel ):
			pass; 				LOG and log('(INT-SEL)')
			set_sel(ed,pSelBgn+1, nSelLen-2, bCrtAtBgn)
#			ed.set_sel(pSelBgn+1, nSelLen-2, bCrtAtBgn)
			return True

		nSelLen2	= len(sInSel)		# ==nSelLen-2 ? 
		sInSelDr	= sInSel
		sInSelRv	= ''.join(reversed(
					  sInSel))

		(nBgnGap
		,nEndGap)	= 0, 0
		for cOp,cCl in mOpBrs.items():
			if cFst==cOp and cLst==cCl:
				if 0:pass #cases
				elif bCrtAtBgn and cCl in sInSelDr: nEndGap	= nSelLen2-findOfNotPair(sInSelDr, cCl)
				elif bCrtAtEnd and cOp in sInSelRv: nBgnGap	= nSelLen2-findOfNotPair(sInSelRv, cOp)
				if 0<nBgnGap+nEndGap:
					pass; 		LOG and log('(P1)*(P2) or ...')
					set_sel(ed,pSelBgn+nBgnGap, nSelLen-nEndGap-nBgnGap, bCrtAtBgn)
#					ed.set_sel(pSelBgn+nBgnGap, nSelLen-nEndGap-nBgnGap, bCrtAtBgn)
					return True 
		if 0:pass #cases
		elif cFst==cQT and cLst==cQT: # and cQT in sInSel
			if 0:pass #cases
			elif bCrtAtBgn: 					nEndGap	= nSelLen2-sInSelDr.find(cQT)
			elif bCrtAtEnd: 					nBgnGap	= nSelLen2-sInSelRv.find(cQT)
		elif cFst==cAP and cLst==cAP: # and cAP in sInSel
			if 0:pass #cases
			elif bCrtAtBgn: 					nEndGap	= nSelLen2-sInSelDr.find(cAP)
			elif bCrtAtEnd: 					nBgnGap	= nSelLen2-sInSelRv.find(cAP)
		pass;					LOG and log('nBgnGap,nEndGap={}',(nBgnGap,nEndGap))
		if 0<nBgnGap+nEndGap:
			pass; 				LOG and log('"P1"P2"')	# "
			set_sel(ed,pSelBgn+nBgnGap, nSelLen-nEndGap-nBgnGap, bCrtAtBgn)
#			ed.set_sel(pSelBgn+nBgnGap, nSelLen-nEndGap-nBgnGap, bCrtAtBgn)
			return True 

		if	self.reAlNms is None:
			self.reAlNms = re.compile(r'^\w+')
		sSelDr		= sSel
		sSelRv		= ''.join(reversed(sSelDr))
		(nBgnGap
		,nEndGap)	= 0, 0
		if 0:pass #cases
		elif bCrtAtBgn and (cFst.isalnum() or cFst=='_'):
			nEndGap	= nSelLen-len(self.reAlNms.search(sSelDr).group())	# Rely: isalnum ~ reAlNms
		elif bCrtAtEnd and (cLst.isalnum() or cLst=='_'):
			nBgnGap	= nSelLen-len(self.reAlNms.search(sSelRv).group())	# Rely: isalnum ~ reAlNms
		pass;					LOG and log('nBgnGap,nEndGap={}',(nBgnGap,nEndGap))
		if 0<nBgnGap+nEndGap:
			pass; 				LOG and log('ABC... or ...ABC')
			set_sel(ed,pSelBgn+nBgnGap, nSelLen-nEndGap-nBgnGap, bCrtAtBgn)
#			ed.set_sel(pSelBgn+nBgnGap, nSelLen-nEndGap-nBgnGap, bCrtAtBgn)
			return True 
		
		sAlNms	=	( '_'
					+ '0123456789'
					+ 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
					+ 'abcdefghijklmnopqrstuvwxyz'
					+ 'ЁЙЦУКЕНГШЩЗХЪФЫВАПРОЛДЖЭЯЧСМИТЬБЮ'
					+ 'ёйцукенгшщзхъфывапролджэячсмитьбю' 
					)
		if cFst in sAlNms or cLst in sAlNms:	# and not "near" caret
			sStripped	= sSel.strip(sAlNms)
			if sStripped!='':
				pass; 			LOG and log('ALNUM')
				nBgnGap	= sSel.index(sStripped)
				set_sel(ed,pSelBgn+nBgnGap, len(sStripped), bCrtAtBgn) 
#				ed.set_sel(pSelBgn+nBgnGap, len(sStripped), bCrtAtBgn) 
				return True
			
		pass; 					LOG and log('FAIL')
#		sSignBlns	= self.SIGNS			+chr(9)+chr(10)+chr(13)
		sSignBlns	= self.SIGNS+cAP+cQT+' '+chr(9)+chr(10)+chr(13)
		if cFst in sSignBlns or cLst in sSignBlns:
			sStripped	= sSel.strip(sSignBlns)
			if sStripped!='':
				pass; 			LOG and log('SIGNS-BLANKS')
				nBgnGap	= sSel.index(sStripped)
				set_sel(ed,pSelBgn+nBgnGap, len(sStripped), bCrtAtBgn) 
#				ed.set_sel(pSelBgn+nBgnGap, len(sStripped), bCrtAtBgn) 
				return True
		
		return False
		#def _narrowOnly
	#class Command

def findOfNotPair(sTx, cWhat):
	""" en:
		Find position of cWhat with skip all pairs.
		Result		Found position or -1
		ru: 
		Поиск не парного символа cWhat.
		Результат	Позиция непарного символа или -1, если не найден.
		
		Examples
			2 ==findOfNotPair('ab}c'   ,'}') 
			-1==findOfNotPair('a{b}c'  ,'}') 
			5 ==findOfNotPair('a{b}c}e','}') 
			5 ==findOfNotPair('a}b{c}e','}') 
	"""
	cPair	= mPairs.get(cWhat)
	if cPair is None:	return -1
	pRsp	= sTx.find(cWhat)
	while pRsp!=-1 and sTx.count(cWhat,0,pRsp)!=sTx.count(cPair,0,pRsp):
		pRsp	= sTx.find(cWhat,pRsp+1)
	return pRsp
	#def findOfNotPair

def set_clip(sText):
	if sw.app_api_version()<='1.0.122': 
		return sw.set_clip(sText)
	if sw.app_api_version()>='1.0.123': 
		return sw.app_proc(sw.PROC_SET_CLIP, sText)
	# set_clip

def lock_status(bLock):
	if '1.0.22'>=sw.app_api_version()>='1.0.119': 
		return sw.app_lock(sw.LOCK_STATUS		if bLock else sw.UNLOCK_STATUS)
	if 			 sw.app_api_version()>='1.0.123': 
		return sw.app_proc(sw.PROC_LOCK_STATUS	if bLock else sw.PROC_UNLOCK_STATUS)
	# lock_status
	
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
		lock_status(True)
		edSW.lock()
		edSW.set_caret_pos(pBgn+nLen)
		for step in range(nLen):
			edSW.cmd(cmd_SelLeft, '')	# 1 or 2 chars selected (2 = CRLF) 
			if pBgn==edSW.get_caret_pos():
				break
		edSW.unlock()
		lock_status(False)
	else:
		if pOldCrt==pBgn and nLen>0:
			# 2. Direct selection from caret
			#pass;				LOG and log('DIR')
			edSW.set_caret_pos(1+pBgn)	# Hack! Move caret to any pos!=pOldCrt 
		edSW.set_sel(pBgn, nLen) 
	#pass;						LOG and log('<<get_caret_pos()={}',(edSW.get_caret_pos()))
	#def set_sel

######################################
def log(msg='', *args):
	""" en:
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
	if True: # add "location"
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
	""" en:
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
if __name__ == '__main__':
	pass;						print('OK')
	
""" TODO
"""