# coding: cp1251

import	configparser

def convert(sOldFile='', sNewFile=''):
	""" Перенос данных из старого формата сессии в новый.
	Параметры:
		имя старого файла
		имя нового файла.
	Зависимости:
		import	configparser
	Старый формат:
		[Ini]
		Files=полное число вкладок в 2х видах
		PageCount=число вкладок в левом виде
		PageActive= 0 или 1 - активность второго вида
		Page=номер акт вкладки в левом виде (от 0)
		Page2=номер акт вкладки в правом виде (от 0)
		SplitHorz= 0 или 1 - сплиттер видов горизонтален
		SplitPos=сплиттер видов, позиция как %
			Потом идут секции, где внутри имена # - номер от 0
		[FN]
		#=имя файла в utf8 или пусто
		[Top]
		#= номер верхней видимой строки (0 based) в editor master (верхний редактор при сплите вкладки)
		[Top2]
		#= номер верхней видимой строки в slave
		[Cur]
		#= позиция как смещение, каретки в master
		[Cur2]
		#= позиция как смещение, каретки в slave
		[RO]
		#= 0 или 1 для readonly
		[Wrap]
		#= 0 или 1 для wrap mode в master
		[Wrap2]
		#= 0 или 1 для wrap mode в slave
		[Line]
		#= 0 или 1 для line nums visible
		[Fold]
		#= 0 или 1 для folding en
		[SelMode]
		#= int для selection mode (от 0), master
		[SelMode2]
		#= int для selection mode (от 0), slave
		[Color]
		#=цвет таба int
		[ColMarkers]
		#=строка, маркеры колонок, пример "10 20 5" (не парсите)
		[Collapsed]
		#=строка, collapsed ranges, master (не парсите)
		[Collapsed2]
		#=строка, collapsed ranges, slave
	Новый формат:
		[sess]
		gr_mode=4				Номер режима групп (1...)
									1 - one group
									2 - two horz
									3 - two vert
		gr_act=4				Номер активной группы (1..6)
		tab_act=0,0,1,2,0,0		Номера активных вкладок на каж группе (от 0, -1 значит нет вкладок)
		split=50				Позиция сплиттера (int в процентах), только для режимов 1*2, 2*1 и 1+2, иначе 50
		tabs=					Число вкладок, оно только для оценки "много ли"
			Потом идут секции [f#] где # - номер вкладки от 0
		[f0]
		gr=						Номер группы (1..6)
		fn=						Имя файла utf8 (точку ".\" не парсить)
		top=10,20				Два числа - top line для master, slave
		caret=10,20				Два числа - каретка для master, slave
		wrap=0,0				Два bool (0/1) - wrap mode для master, slave
		prop=0,0,0,0,			4 числа через зап.
			- r/o (bool)
			- line nums visible (bool)
			- folding enabled (bool) - (NB! Было раньше disabled)
			- select mode (0..)
		color=					Цвет таба (строка та же)
		colmark=				Col markers (строка та же)
		folded=					2 строки через ";" - collapsed ranges для master, slave
	"""
	# Подготовка
	cfgOld = configparser.ConfigParser()
	cfgOld.read(sOldFile, encoding='utf-8')
	cfgNew = configparser.ConfigParser()

	# Преобразование
	scOIni	= cfgOld['Ini']
	nFs		= int(scOIni['Files'])
	cfgNew['sess']	= {
		'gr_mode'	:icase(False,''
						,'0'==scOIni['PageCount'], '1'			# Нет доп.панели
						,'0'==scOIni['SplitHorz'], '2'			# Доп.панель справа
						,'1'==scOIni['SplitHorz'], '3'			# Доп.панель снизу
						)
	,	'gr_act'	:icase('0'==scOIni['PageActive'], '1', '2')	# Фокус в доп.панели
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

	# Сохранение
	with open(sNewFile,'w',encoding='utf-8') as out:
		cfgNew.write(out, space_around_delimiters=False)
	#def sessOld2New

#######################################################
def icase(*pars):
	""" en:
		Params	cond1,val1[, cond2,val2, ...[, valElse]...]
		Result	Value for first true cond in pairs otherwise last odd param or None
		ru:
		Параметры	усл-1,знач-1[, усл-2,знач-2, ...[, знач-Иначе]...]
		Результат	Первое значение, для которого есть парное истинное условие.
					Иначе последний нечетный параметр, а если его нет, то None
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

