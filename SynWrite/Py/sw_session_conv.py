# coding: cp1251

import	configparser

def convert(sOldFile='', sNewFile=''):
	""" ������� ������ �� ������� ������� ������ � �����.
	���������:
		��� ������� �����
		��� ������ �����.
	�����������:
		import	configparser
	������ ������:
		[Ini]
		Files=������ ����� ������� � 2� �����
		PageCount=����� ������� � ����� ����
		PageActive= 0 ��� 1 - ���������� ������� ����
		Page=����� ��� ������� � ����� ���� (�� 0)
		Page2=����� ��� ������� � ������ ���� (�� 0)
		SplitHorz= 0 ��� 1 - �������� ����� ������������
		SplitPos=�������� �����, ������� ��� %
			����� ���� ������, ��� ������ ����� # - ����� �� 0
		[FN]
		#=��� ����� � utf8 ��� �����
		[Top]
		#= ����� ������� ������� ������ (0 based) � editor master (������� �������� ��� ������ �������)
		[Top2]
		#= ����� ������� ������� ������ � slave
		[Cur]
		#= ������� ��� ��������, ������� � master
		[Cur2]
		#= ������� ��� ��������, ������� � slave
		[RO]
		#= 0 ��� 1 ��� readonly
		[Wrap]
		#= 0 ��� 1 ��� wrap mode � master
		[Wrap2]
		#= 0 ��� 1 ��� wrap mode � slave
		[Line]
		#= 0 ��� 1 ��� line nums visible
		[Fold]
		#= 0 ��� 1 ��� folding en
		[SelMode]
		#= int ��� selection mode (�� 0), master
		[SelMode2]
		#= int ��� selection mode (�� 0), slave
		[Color]
		#=���� ���� int
		[ColMarkers]
		#=������, ������� �������, ������ "10 20 5" (�� �������)
		[Collapsed]
		#=������, collapsed ranges, master (�� �������)
		[Collapsed2]
		#=������, collapsed ranges, slave
	����� ������:
		[sess]
		gr_mode=4				����� ������ ����� (1...)
									1 - one group
									2 - two horz
									3 - two vert
		gr_act=4				����� �������� ������ (1..6)
		tab_act=0,0,1,2,0,0		������ �������� ������� �� ��� ������ (�� 0, -1 ������ ��� �������)
		split=50				������� ��������� (int � ���������), ������ ��� ������� 1*2, 2*1 � 1+2, ����� 50
		tabs=					����� �������, ��� ������ ��� ������ "����� ��"
			����� ���� ������ [f#] ��� # - ����� ������� �� 0
		[f0]
		gr=						����� ������ (1..6)
		fn=						��� ����� utf8 (����� ".\" �� �������)
		top=10,20				��� ����� - top line ��� master, slave
		caret=10,20				��� ����� - ������� ��� master, slave
		wrap=0,0				��� bool (0/1) - wrap mode ��� master, slave
		prop=0,0,0,0,			4 ����� ����� ���.
			- r/o (bool)
			- line nums visible (bool)
			- folding enabled (bool) - (NB! ���� ������ disabled)
			- select mode (0..)
		color=					���� ���� (������ �� ��)
		colmark=				Col markers (������ �� ��)
		folded=					2 ������ ����� ";" - collapsed ranges ��� master, slave
	"""
	# ����������
	cfgOld = configparser.ConfigParser()
	cfgOld.read(sOldFile, encoding='utf-8')
	cfgNew = configparser.ConfigParser()

	# ��������������
	scOIni	= cfgOld['Ini']
	nFs		= int(scOIni['Files'])
	cfgNew['sess']	= {
		'gr_mode'	:icase(False,''
						,'0'==scOIni['PageCount'], '1'			# ��� ���.������
						,'0'==scOIni['SplitHorz'], '2'			# ���.������ ������
						,'1'==scOIni['SplitHorz'], '3'			# ���.������ �����
						)
	,	'gr_act'	:icase('0'==scOIni['PageActive'], '1', '2')	# ����� � ���.������
	,	'tab_act'	:scOIni['Page']		+','+	scOIni['Page2']
	,	'split'		:scOIni['SplitPos']
	,	'tabs'		:nFs
	}
	for n,sN in ((n,'{}'.format(n)) for n in range(nFs)):
		cfgNew['f'+sN]	= {}
		scNFn			= cfgNew['f'+sN]
		scNFn['gr']		= icase(n<=int(scOIni['PageCount']), '1', '2')
		scNFn['fn']		= cfgOld['FN'][sN]
		scNFn['color']	= cfgOld['Color'][sN]
		scNFn['colmark']= cfgOld['ColMarkers'][sN]
		scNFn['top']	= cfgOld['Top'][sN]			+','+	cfgOld['Top2'][sN]
		scNFn['caret']	= cfgOld['Cur'][sN]			+','+	cfgOld['Cur2'][sN]
		scNFn['wrap']	= cfgOld['Wrap'][sN]		+','+	cfgOld['Wrap2'][sN]
		scNFn['folded']	= cfgOld['Collapsed'][sN]	+';'+	cfgOld['Collapsed2'][sN]
		scNFn['prop']	= '{},{},{},{}'.format(
								cfgOld['RO'][sN]
							,	cfgOld['Line'][sN]
							,	{'0':'1','1':'0'}[cfgOld['Fold'][sN]]
							,	cfgOld['SelMode'][sN]
							)

	# ����������
	with open(sNewFile,'w',encoding='utf-8') as out:
		cfgNew.write(out, space_around_delimiters=False)
	#def sessOld2New

#######################################################
def icase(*pars):
	""" en:
		Params	cond1,val1[, cond2,val2, ...[, valElse]...]
		Result	Value for first true cond in pairs otherwise last odd param or None
		ru:
		���������	���-1,����-1[, ���-2,����-2, ...[, ����-�����]...]
		���������	������ ��������, ��� �������� ���� ������ �������� �������.
					����� ��������� �������� ��������, � ���� ��� ���, �� None
		Examles
			icase(1==2,'a', 3==3,'b') == 'b'
			icase(1==2,'a', 3==4,'b', 'c') == 'c'
			icase(1==2,'a', 3==4,'b') == None
	"""
	for ppos in range(1,len(pars),2) :
		if pars[ppos-1] :
			return pars[ppos]
	return pars[-1] if 1==len(pars)%2 else None
	#def icase

