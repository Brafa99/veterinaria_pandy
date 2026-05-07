const admin = require('firebase-admin');
const serviceAccount = require(`./pandy_firestore.json`);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

/**
 * IMPORTANTE: He envuelto cada campo de texto en BACKTICKS ( ` ) 
 * para que los saltos de línea no rompan el código.
 */
const sqlData = [
(`25792`,`P 3.350 kg se observa paciente con perdida de pelo podrÃ­a ser causa hormonal se sugiere castraciÃ³n tambiÃ©n se recomienda alimento balanceado fino trato cachorro 95 g x dÃ­a gomitas de colÃ¡geno 2 x dÃ­a 
\nalimento 200 bs 
\ngomitas 30 bs `,`2026-04-25`,`Consulta Medica`,`5523`,`5`,`230`,``),
(`25793`,`.`,`2026-04-25`,``,`12`,`5`,`0`,``),
(`25794`,`P 3.150 kg T38.8Â° paciente presenta vÃ³mitos lÃ­quidos y deposiciones liquidas de color cafÃ© oscuro  se realiza prueba de parvovirus dando positivo se inicia tratamiento intravenoso TTo IV suero ringer Dipi 0.15 ml gastrine 0.15 ml suero glucosado hepa 0.5ml SC gastroglobulin 3 ml IM enrolh 0.3 ml VO metronidazol 0.3 ml c/ 12 hrs x 7 dias 
\nprueba 100bs 
\ntratamiento 180 bs 
\njarabe 50 bs 
\ntratamiento de domingo 180 bs `,`2026-04-25`,`Consulta Medica`,`5862`,`5`,`510`,``),
(`25795`,`Peso 1.560 kg, 1Â°  Triple felina`,`2026-04-25`,`Consulta Medica`,`5782`,`5`,`100`,``),
(`25796`,`BaÃ±o y Corte`,`2026-04-25`,`Peluqueria`,`5011`,`5`,`100`,``),
(`25797`,`apetito normal  y animoTTo GX 0.8 ml Dipi 0.4 ml gastrine 0.4 ml hepa 1.5 ml`,`2026-04-25`,`Consulta Medica`,`3678`,`5`,`0`,``),
(`25798`,`quemacuran crema dada de alta `,`2026-04-25`,`Consulta Medica`,`5632`,`5`,`0`,``),
(`25799`,`dada de alta gomitas de colÃ¡geno `,`2026-04-25`,`Consulta Medica`,`5852`,`5`,`30`,``),
(`25800`,`TTo 1o  dosis mensual Artrosan  1 ml`,`2026-04-25`,`Consulta Medica`,`4712`,`5`,`120`,``),
(`25801`,`se observa mejoria  TTo enrolab 0.7 ml dexa 0.7 ml `,`2026-04-25`,`Consulta Medica`,`249`,`5`,`0`,``),
(`25802`,`  se observa mejoria Tto ceftriaxona 1.6 ml `,`2026-04-25`,``,`5212`,`5`,`0`,``),
(`25803`,`BaÃ±o y corte`,`2026-04-25`,`Peluqueria`,`2114`,`5`,`150`,``),
(`25804`,`buena evoluciÃ³n terminando el jarabe se realiza control TTo enrolab 0.7 ml dexa 0.7 ml`,`2026-04-26`,`Consulta Medica`,`249`,`5`,`0`,``),
(`25805`,`TTo enrolab 0.7 ml dexa 0.7 ml`,`2026-04-26`,`Consulta Medica`,`5212`,`5`,`0`,``),
(`25806`,`TTo IV suero ringer Dipi 0.15 ml gastrine 0.15 ml suero glucosado hepa 0.5ml SC gastroglobulin 3 ml IM enrolh 0.3 ml VO metronidazol 0.3 ml c/ 12 hrs x 7 dias`,`2026-04-26`,`Consulta Medica`,`5862`,`5`,`0`,``),
(`25807`,`P 45.400 kg herida en parpado superior derecho por traumatismo se realizo sutura de dos puntos TTo dexa 2.3 ml gx 4.5 ml `,`2026-04-26`,`Consulta Medica`,`670`,`5`,`200`,``),
(`25808`,`P 33.400 kg se observa paciente con herida  en la oreja izquierda por traumatismo curabichera plata TTo GX 3 ml dexa 1.5 ml `,`2026-04-26`,`Consulta Medica`,`2581`,`5`,`100`,``),
(`25809`,`P 4.450 KG se observa paciente con dermatitis generalizado y lesiones en la espalda se solicita raspado cutaneo y antibiograma `,`2026-04-27`,`Consulta Medica`,`1584`,`5`,`80`,``),
(`25810`,`P 1.300 kg se reinicia vacunaciÃ³n por atraso en la fecha 1o vacuna triple felina de 2 `,`2026-04-27`,`Consulta Medica`,`5763`,`5`,`100`,``),
(`25811`,`P 1.550 kg 1o vacuna triple felina de 2 `,`2026-04-27`,`Consulta Medica`,`5863`,`5`,`100`,``),
(`25812`,`Peso 22,900Kg, dermatitis hÃºmeda presenta en el inicio de la cola dorsal en el medio de los pliegues, presenta leve supuraciÃ³n con sangre,  Tto dexa 1.2ml y ceftionel50 1.5ml, demavet crema 2veces por dia por 7dias 
\ncrema 85
\ntratamiento 200`,`2026-04-27`,`Consulta Medica`,`3264`,`5`,`285`,``),
(`25813`,`P:5.750kg presenta periodontitis, leve bradicardia, alimentaciÃ³n casera con pollo, se comienza tratamiento el 3dia se programa limpieza dental el 30 de abril, Tto ceftriaxona 0.5ml keto 0.1ml
\ntratamiento 200
\nLD 140bs
\n100bs a cuenta DEBE 240BS`,`2026-04-27`,`Consulta Medica`,`579`,`5`,`340`,``),
(`25814`,`Peso 13,700Kg TÂ° 39,5 Traqueobronquitis, TrÃ¡quea inflamada, duerme afuera, presenta arcadas, pulmones limpios, ayer no comiÃ³ nada, deposiciones normales, no tiene vacunas al dia Tto: dexa 0,7ml, enrolab 0,7ml pago el tratamiento completo`,`2026-04-27`,`Consulta Medica`,`2052`,`5`,`200`,``),
(`25815`,`buena cicatrizaciÃ³n, se aplico quemacuran, se toco un poco porq le retiraron la faja un momento`,`2026-04-27`,`Consulta Medica`,`5859`,`5`,`0`,``),
(`25816`,`aun se observa deposiciones liquidas y decaimiento TTo IV suero ringer Dipi 0.15 ml gastrine 0.15 ml suero glucosado hepa 0.5ml SC gastroglobulin 3 ml IM enrolh 0.3 ml VO metronidazol 0.3 ml c/ 12 hrs x 7 dias`,`2026-04-27`,`Consulta Medica`,`5862`,`5`,`180`,``),
(`25817`,`Ã³ctuple (4-4), se programa rabia 16 de Mayo`,`2026-04-27`,`Consulta Medica`,`5726`,`5`,`100`,``),
(`25818`,`P 22.950 kg se observa paciente con prolapso del lagrimal del ojo izquierdo con ulceraciÃ³n del ojo se sugiere cirugÃ­a de igual manera la misma no esta esterilizada tambiÃ©n se sugiere cirugÃ­a TTo ocuflox 1 gota c/ 12 hrs x 7 dÃ­as
\nmedicaciÃ³n 140 bs `,`2026-04-27`,`Consulta Medica`,`2640`,`5`,`140`,``),
(`25819`,`Peso 3,900Kg paciente que presenta aguja incrustada en las encÃ­as provocando leve sangrado se realizo e retiro del objeto TTo fortepen 0.3 ml keto 0.1 ml `,`2026-04-27`,`Consulta Medica`,`5058`,`5`,`90`,``),
(`25820`,`PRESENTA UNA ALTERACION DE COMPORTAMIENTO, muy nerviosa, come podium, antes comia ecopet.  Peso 18.800 kg. TTo ocuflox 1 gota cada 24 hrs x 7 dias 
\nmedicacion 140 bs 
\nconsulta 80 bs  `,`2026-04-27`,`Consulta Medica`,`1626`,`5`,`220`,``),
(`25821`,`BaÃ±o y corte`,`2026-04-27`,`Peluqueria`,`2303`,`5`,`100`,``),
(`25822`,`buena evoluciÃ³n TTo dexa 2.3 ml gx 4.5 ml`,`2026-04-27`,`Consulta Medica`,`670`,`5`,`100`,``),
(`25823`,`P 2.310 OVH X 0.3 ml K 0.2 ml A 0.1 ml Ceftrioxona 0.5 ml keto 01 ml 
\ncirugÃ­a 150 bs
\nfaja 50 bs `,`2026-04-27`,`Consulta Medica`,`5716`,`5`,`200`,``),
(`25824`,`P 1.700 kg OVH X 0.3 ml K 0.2 ml A 0.1 ml Ceftrioxona 0.5 ml keto 01 ml cirugÃ­a 150 bs faja 50 bs`,`2026-04-27`,`Consulta Medica`,`5717`,`5`,`200`,``),
(`25825`,`buena evoluciÃ³n menor inflamaciÃ³n  TTo GX 3 ml dexa 1.5 ml`,`2026-04-27`,`Consulta Medica`,`2581`,`5`,`100`,``),
(`25826`,`Tto ceftriaxona 0.5ml keto 0.1ml `,`2026-04-28`,`Consulta Medica`,`579`,`5`,`0`,``),
(`25827`,`se observa mejoria aun no hay apetito Tto: dexa 0,7ml, enrolab 0,7ml`,`2026-04-28`,`Consulta Medica`,`2052`,`5`,`0`,``),
(`25828`,`BaÃ±o y corte`,`2026-04-28`,`Peluqueria`,`823`,`5`,`100`,``),
(`25829`,`P 2.250 kg se realiza inicio del calendario de vacunas ya que no se tiene certeza de haber recibido vacunaciÃ³n anteriormente 1o octuple de 3 y corte de uÃ±as `,`2026-04-28`,`Consulta Medica`,`5833`,`5`,`130`,``),
(`25830`,`SE RESENTA MENOR HUMEDAD EN EL ARE DE L COLA, Tto dexa 1.2ml y ceftionel50 1.5ml,`,`2026-04-28`,`Consulta Medica`,`3264`,`5`,`0`,``),
(`25831`,`BAÃ‘O Y PEINDO`,`2026-04-28`,`Peluqueria`,`3158`,`5`,`100`,``),
(`25832`,`PESO 7.600 KG, VACUNA VOCTUPLE Y DESPA`,`2026-04-28`,`Consulta Medica`,`3158`,`5`,`130`,``),
(`25833`,` QUIMICA SANGUINEA: GLICEMIA 53.1 (70 - 140 mg/dl), FOSFATASA ALCALINA 273.4 (68 - 240 U/L)
\nGAMA GLUTAMIL TRANSFERASA (GGT) 18.2 (<= 12 U/L), AMILASA 1740.0 (269 - 1462 U/L), LIPASA 510.6 (50 - 470 U/L), FOSFORO 6.6 (2.0 - 6.2 mg/dl). HEMOGRAMA Leucocitos 23400 (6000-16000 mmÂ³), Segmentados 90 % (60-77 %),  V.E.S. 15 (0-10 mm), emesis, decaimiento, se observa flujo vaginal se presume infeccion urinaria Tto IV suero ringer rilexin 3ml, Rani 1.8ml, suero glucosado 5% ceftriaxona 1ml, hepatin 3ml
\n`,`2026-04-28`,`Consulta Medica`,`3678`,`5`,`120`,``),
(`25834`,` P 0.370 kg pasara el periodo de adaptaciÃ³n hasta una semana se sugiere alimentaciÃ³n con croquetas el mismo usa balancead 30 g diarios. Concluyendo el periodo de adaptaciÃ³n se harÃ¡ la desparasitaciÃ³n  `,`2026-04-28`,`Consulta Medica`,`5864`,`5`,`80`,``),
(`25835`,`P 11.750 kg T 38 . Paciente presenta tos en las noches hace cuatro meses, trÃ¡quea inflamada, soplo cardiaco, lesiÃ³n en el ojo izquierdo DX asma cardiaco TTo cardial 1/2 comp, c 24 hrs x 10 dÃ­as Dexametasona 1/ 2  comp  c/ 12 hrs x 5 dÃ­as Gotas oftalmin plus 2 gotas c/ 12 hrs x 4 dias inicaialmente 
\ncardial 40 bs 
\n dexa 15 bs 
\n gotas 50 bs DEBE 105 BS 
\n`,`2026-04-28`,``,`4713`,`5`,`105`,``),
(`25836`,`P 23.400kg se observa trÃ¡quea inflamada tambiÃ©n se detecta soplo cardiaco en vÃ¡lvula superior no tan macada 
\nDx traqueo bronquitis TTo  Enrolab 1.2 ml dexa 1,2 ml `,`2026-04-28`,`Consulta Medica`,`4712`,`5`,`200`,``),
(`25837`,`Canitabs  UT Suport 20 comp `,`2026-04-28`,`Consulta Medica`,`3949`,`5`,`100`,``),
(`25838`,`buena evoluciÃ³n se retira faja se continua con quemacuran crema en la herida de la cola `,`2026-04-28`,`Consulta Medica`,`651`,`5`,`0`,``),
(`25839`,`Corte de uÃ±as `,`2026-04-28`,`Consulta Medica`,`4320`,`5`,`20`,``),
(`25840`,`Paciente con buena evoluciÃ³n termino el tratamiento, ya no ay micciÃ³n con sangre se realizara nuevo laboratorio de control culminando las segunda bolsa de alimento, se recomienda continuar con alimento cibau lith 240 g x dia`,`2026-04-28`,`Consulta Medica`,`553`,`5`,`0`,``),
(`25841`,`Paciente dado de alta `,`2026-04-28`,`Consulta Medica`,`5856`,`5`,`0`,``),
(`25842`,`TTo 3Âº Artrosan 2.5 ml  Artrosan 180Bs colÃ¡geno 60 debe 240Bs `,`2026-04-28`,`Consulta Medica`,`2297`,`5`,`240`,``),
(`25843`,`TTo GX 3 ml dexa 1.5 ml`,`2026-04-28`,`Consulta Medica`,`2581`,`5`,`100`,``),
(`25844`,`TTo dexa 2.3 ml gx 4.5 ml`,`2026-04-28`,`Consulta Medica`,`670`,`5`,`100`,``),
(`25845`,`P 4.650 kg refuerzo TTo atriben 0.2 ml gomitas de colÃ¡geno 2 por dia `,`2026-04-28`,`Consulta Medica`,`4692`,`5`,`110`,``),
(`25846`,`P 22.850 OVH y PGL X 2 ml K 0.8 ml A 0.3 ml Suero ringer dipi 1.1 ml rani 4.5 ml vitak 2.2 ml Glucosado ceftroxona 2.2 ml hepatin 2 ml IM cuagulomax 0.9 ml VO cefalexina 1 comp c/ 12 hrs x 5 dias Naxpet 1 comp  x noche x 3 noches continua ocuflox 
\nCirugia 600 bs 
\nfaja 70 bs 
\nmedicacion 71 bs 
\npaÃ±al 12 bs `,`2026-04-28`,`Consulta Medica`,`2640`,`5`,`753`,``),
(`25847`,`Tto IV suero ringer, Rani 1.8ml, suero glucosado 5% ceftriaxona 1ml, hepatin 3ml, vitamifos 1.2 ml  TTo VO  CIPROFLOXACINA 1/2 comprimido cada 24 hrs por 8 dÃ­as 
\nTratamiento 120Bs 
\nComprimidos 12Bs   `,`2026-04-29`,`Consulta Medica`,`3678`,`5`,`132`,``),
(`25848`,`Tto: dexa 0,7ml, enrolab 0,7ml, dado de alta `,`2026-04-29`,`Consulta Medica`,`2052`,`5`,`0`,``),
(`25849`,`Apetito normal, se retira la branula, Debe retornar en 20 dÃ­as para iniciar el esquema de vacunas `,`2026-04-29`,`Consulta Medica`,`5862`,`5`,`0`,``),
(`25850`,`Tto dexa 1.2ml y ceftionel50 1.5ml, Se realiza limpieza del exceso de crema, se coloca sulfa, mantiene la crema 1 vez a dia `,`2026-04-29`,`Consulta Medica`,`3264`,`5`,`0`,``),
(`25851`,`Dado de alta `,`2026-04-29`,`Consulta Medica`,`2706`,`5`,`0`,``),
(`25852`,`P 19.900 kg paciente con inflamaciÃ³n en el dedo del MDI comprometiendo uÃ±a y dedo se realizo punciÃ³n no se observa presencia de pus se realiza tratamiento con antibiÃ³ticos TTo amoxicla 1 ml Dexa 1 ml se coloca media tÃ³pico livre crema aplicar 2 veces al dÃ­a `,`2026-04-29`,``,`3461`,`5`,`290`,``),
(`25853`,`BaÃ±o y corte`,`2026-04-29`,`Peluqueria`,`422`,`5`,`120`,``),
(`25854`,`BaÃ±o y corte`,`2026-04-29`,`Peluqueria`,`4385`,`5`,`100`,``),
(`25855`,`BaÃ±o y corte`,`2026-04-29`,`Peluqueria`,`5787`,`5`,`120`,``),
(`25856`,`Peso 2,100Kg  desparasitaciÃ³n simparica trio y corte de uÃ±as `,`2026-04-29`,`Consulta Medica`,`5446`,`5`,`130`,``),
(`25857`,`P 6.00kg LD X 0.4 ml K0.2 ml A 0.2 ml perdida 4 piezas dentales Ceftriaxona 0.5 ml keto 0.2 ml VO aminovit 10 ml x dia 
\nLD 200 bs 
\nAminovit 50 bs `,`2026-04-29`,`Consulta Medica`,`579`,`5`,`250`,``),
(`25858`,`P 2.500 kg LD x 0.3 ml k 0.2 ml A 0.1 ml IM xila 0.1 ml Keta 0.1 ml Perdida de 2 piezas Ceftriaxona 0.5 ml keto 0.1 ml  Cuagulomax 0.1 ml se realiza curaciÃ³n en boca luego de la cirugÃ­a con X 0.1 ml K 0.1 ml se realiza prÃ©stamo de cono `,`2026-04-29`,``,`1026`,`5`,`200`,``),
(`25859`,`P 3.510 kg LD x 0.3 ml K 0.2 ml A 0.1 ml Perdida de 2 piezas ceftriaxona 0.5 ml keto 0.1 ml IM cuagulomax 0.1 ml `,`2026-04-29`,`Consulta Medica`,`1794`,`5`,`200`,``),
(`25860`,`P4.900 kg se observa paciente con incontinencia urinaria y basados en los resultados de laboratorio  se determina infecciÃ³n urinaria TTo ceftriaxona 0.5 ml Keto 0.1 ml VO urovier 1/4 comp x dÃ­a x 12 dÃ­as gomitas de colÃ¡geno 
\nTratamiento 200 bs 
\nmedicaciÃ³n 24 bs 
\ngomitas de colÃ¡geno 30 bs `,`2026-04-29`,`Consulta Medica`,`2482`,`5`,`254`,``),
(`25861`,`P 12.550 kg se observa paciente con alopecia en el Ã¡rea del pecho y cerca del Ã¡rea bulbar y cola por alergia TTo atriben 0.4 ml refuerzo el jueves 14 de mayo TÃ³pico crema en las arreas de la alopecia dermavet 2 veces al dÃ­a gomitas de colÃ¡geno 2 al dÃ­a 
\ntratamiento 80 bs 
\ncrema 85 bs 
\ncolageno 30 bs `,`2026-04-29`,``,`5865`,`5`,`195`,``),
(`25862`,`resultado de laboratorio positivo a Calicivirus TTo IM Ceftriaxona 0.5 ml dexametasona SC viracel 0.1 ml 
\ntratamiento 120 bs `,`2026-04-30`,`Consulta Medica`,`1026`,`5`,`120`,``),
(`25863`,`BaÃ±o y cepillado`,`2026-04-30`,`Peluqueria`,`3947`,`5`,`150`,``),
(`25864`,`se observa mejoria ya no hay micciÃ³n con incontinencia TTo ceftriaxona 0.5 ml Keto 0.1 ml `,`2026-04-30`,`Consulta Medica`,`2482`,`5`,`0`,``),
(`25865`,`BaÃ±o y Corte`,`2026-04-30`,`Consulta Medica`,`771`,`5`,`100`,``),
(`25866`,`P 8.200 kg se observa paciente con herida por mordedura en pecho cerca del MDD se realizo sutura de 4 puntos TTo fortepen 0.8 ml dexa 0.4 ml gomitas de colÃ¡geno 2 por dÃ­a 
\ntratamiento 170 bs 
\ncolageno 30 bs   `,`2026-04-30`,`Consulta Medica`,`5866`,`5`,`200`,``),
(`25867`,`Peso 3.600kg, paciente dada de alta, llevo gomitas de colÃ¡geno 30bs`,`2026-04-30`,``,`5527`,`5`,`30`,``),
(`25868`,`bajo la inflamaciÃ³n buena evoluciÃ³n TTo amoxicla 1 ml Dexa 1 ml `,`2026-04-30`,`Consulta Medica`,`3461`,`5`,`0`,``),
(`25869`,`retiro de puntos se observa que la paciente se lamio la herida control el dÃ­a lunes gomitas de colÃ¡geno 
\nvacuna rabia `,`2026-04-30`,``,`5859`,`5`,`100`,``),
(`25870`,`buena evoluciÃ³n ultima revisiÃ³n el dÃ­a lunes `,`2026-04-30`,`Consulta Medica`,`651`,`5`,`0`,``),
(`25871`,`Peso:2.400kg LD. IM X:0.3ML, K:02ml, A:01ml ExtracciÃ³n de 4 piezas dentales, IM Cuagu 0.1ml, TTo Dexa 0.1ml, Ceftrixona 0.5ml, SC Viracel 0.1ml
\nLD: 200
\nTto:100  `,`2026-04-30`,`Consulta Medica`,`3963`,`5`,`300`,``),
(`25872`,`Peso: 3.850kg, LD.  IM X:0.3ml, K:0.2ml, A: 0.1ml, ExtracciÃ³n : 3 piezas dentales. TTo  IM Dexa 0.1ml, Ceftrixona 0.5ml. SC Viracel 0.1ml 
\nLD: 200
\nTto: 100 `,`2026-04-30`,`Consulta Medica`,`1793`,`5`,`300`,``),
(`25873`,`buena evoluciÃ³n dada de alta TTo cetriaxona 1 ml rani 1.8 hepa 1,5 ml `,`2026-04-30`,`Consulta Medica`,`3678`,`5`,`80`,``),
(`25874`,`TTo Dexa 0.1ml, Ceftrixona 0.5ml, SC Viracel 0.1ml `,`2026-05-01`,`Consulta Medica`,`3963`,`5`,`0`,``),
(`25875`,` TTo IM Ceftriaxona 0.5 ml dexametasona SC viracel 0.1 ml`,`2026-05-01`,`Consulta Medica`,`1026`,`5`,`0`,``),
(`25876`,`TTo IM Dexa 0.1ml, Ceftrixona 0.5ml. SC Viracel 0.1ml `,`2026-05-01`,`Consulta Medica`,`1793`,`5`,`0`,``),
(`25877`,`TTo ceftriaxona 0.5 ml Keto 0.1 ml`,`2026-05-01`,`Consulta Medica`,`2482`,`5`,`0`,``),
(`25878`,`Vaciado de Glandulas Perianales, irritacion en el area anal.`,`2026-05-01`,`Consulta Medica`,`4831`,`5`,`90`,``),
(`25879`,` TTo amoxicla 1 ml Dexa 1 ml`,`2026-05-01`,`Consulta Medica`,`3461`,`5`,`0`,``),
(`25880`,`TTo Ultimo dÃ­a de fortepen 0.8 ml dexa 0.4 ml , maÃ±ana solo control`,`2026-05-01`,`Consulta Medica`,`5866`,`5`,`0`,``),
(`25881`,`Buena evoluciÃ³n, se aplica quemacuran  Dado de alta `,`2026-05-02`,`Consulta Medica`,`4831`,`5`,`0`,``),
(`25882`,`...`,`2026-05-02`,``,`3077`,`5`,`0`,``),
(`25883`,`Peso 9,200kg se retira la uÃ±a que la tenia rota desde el dÃ­a jueves Atriben ml `,`2026-05-02`,``,`721`,`5`,`100`,``),
(`25884`,`Peso: 5.550kg. presenta dolor en el MAI, principio de artrosis. Tto: IM melox 0.2 ml, Complejo B 1.5ml
\ncolageno 
\nTto: 140
\nColageno 30`,`2026-05-02`,`Consulta Medica`,`1580`,`5`,`170`,``),
(`25885`,`TTo IM Dexa 0.1ml, Ceftrixona 0.5ml. SC Viracel 0.1ml`,`2026-05-02`,`Consulta Medica`,`1793`,`5`,`0`,``),
(`25886`,`TTo Dexa 0.1ml, Ceftrixona 0.5ml, SC Viracel 0.1ml`,`2026-05-02`,`Consulta Medica`,`3963`,`5`,`0`,``),
(`25887`,`1,350kG  1-2 Triple Felna`,`2026-05-02`,``,`5814`,`5`,`100`,``),
(`25888`,`BaÃ±o y cepillado`,`2026-05-02`,`Peluqueria`,`2699`,`5`,`150`,``),
(`25889`,` P 4.350 KG TTo `,`2026-05-02`,`Consulta Medica`,`1584`,`5`,`0`,``),
(`25890`,`Raspado cutaneo: Presencia de macroconidias y microconidios fusiformes, ademÃ¡s de levaduras y hongos compatible morfolÃ³gicamente con el gÃ©nero(Microsporum spp.), CIPROFLOXACINA Intermedio ENROFLOXACINA Intermedio. La DueÃ±a indica que fuew diagnosticada con alegia cronica y tomaba prednizona,  uso diferentes shampus medicados y la baÃ±a una vez a la semana. Peso: 4.350 kg, Tto: Ciprfloxacina oral 1/4 comp c/24 hr/8/dias 6 bs, Fungovet 2 veces al adia 7 dias 50 bs.`,`2026-05-02`,`Consulta Medica`,`1584`,`5`,`56`,``),
(`25891`,`BVaÃ±o y corte`,`2026-05-02`,`Peluqueria`,`826`,`5`,`120`,``),
(`25892`,`enzimol 4 comp. c/ 12 hrs x 7 dias 280 bs, simparica trio 130 bs`,`2026-05-02`,`Consulta Medica`,`826`,`5`,`410`,``),
(`25893`,`BaÃ±o y corte`,`2026-05-02`,`Peluqueria`,`2373`,`5`,`100`,``),
(`25894`,`BaÃ±o y corte`,`2026-05-02`,`Peluqueria`,`1317`,`5`,`100`,``),
(`25895`,`Peso : 14.700 kg, Durante el procedimiento de BaÃ±o se detecta Otitis Unilateral oÃ­do Izquierdo. Tto Gendilex 2 gotas cada 8 horas por 7 dÃ­as `,`2026-05-02`,`Consulta Medica`,`2373`,`5`,`80`,``),
(`25896`,`3Â° dosis semanal de Artrosan 2.3ml Peso 46.500 kg`,`2026-05-02`,``,`527`,`5`,`150`,``),
(`25897`,`Peso: 1.080 Ks RevisiÃ³n general sin alteraciones clÃ­nicas ni signos clÃ­nicos, deps Vermic.`,`2026-05-02`,``,`5867`,`5`,`80`,``),
(`25898`,`Paciente con buena evoluciÃ³n, se recomienda continuar con la crema 1 vez al dÃ­a durante 3 dÃ­as `,`2026-05-02`,`Consulta Medica`,`5212`,`5`,`0`,``),
(`25899`,`BaÃ±o y corte`,`2026-05-02`,`Peluqueria`,`1310`,`5`,`100`,``),
(`25900`,`Alergia crÃ³nica Peso 7,500Kg  Atriben 0,3ml `,`2026-05-02`,`Consulta Medica`,`1310`,`5`,`80`,``),
(`25901`,`BaÃ±o y cepillado`,`2026-05-02`,`Peluqueria`,`1309`,`5`,`150`,``),
(`25902`,`BaÃ±o y corte`,`2026-05-02`,`Peluqueria`,`3077`,`5`,`100`,``),
(`25903`,`Excelente evoluciÃ³n, se aplico quemacuran , control y posible retiro de puntos dÃ­a martes`,`2026-05-02`,``,`5866`,`5`,`0`,``),
(`25904`,`OVH peso 12,400Kg Xila 0,8ml,keta 0,4ml,atro 0,2ml, VÃ­a intravenosa Suero ringer dipi 0,6ml, rani 2,5ml, vitamina K 1,2ml,Suero glucosado hepatin 2ml, ceftriaxona 1,2ml, IM cuagulomax 0,5ml, TToO CEFALEXINA 1/2 COMPRIMIDO CADA 12 HORAS POR 5 DIAS ,naxpet 1/2 Comprimido cada noche por 4 noches 
\nCirugÃ­a 250
\nFaja 65
\nComprimidos 39 `,`2026-05-02`,`Consulta Medica`,`5268`,`5`,`354`,``),
(`25905`,`P:6.300kg MAI el miÃ©rcoles salto de la cama segÃºn indica el dueÃ±o, presenta desde ese dÃ­a leve cojera, el jueves no podÃ­a pisar Tto meloxi 0.2ml y Bplex 1ml, se recomendÃ³ implementar rampa para la cama, y colÃ¡geno `,`2026-05-03`,`Consulta Medica`,`3800`,`5`,`90`,``),
(`25906`,`2-5-2026 Peso 11,700Kg Posiblemente comiÃ³ huesos de pollo y algarroba Vomito croquetas 3 veces el dÃ­a de hoy Tto: gentamox 1.1ml,dipi 0,5ml, gastrine 0,5ml, hepatin 1ml.
\n3-5-2026 no presenta vÃ³mitos, deposiciones normales, bajo la inflamaciÃ³n de la nariz dorsal, mejor animo Tto: gentamox 1.1ml,dipi 0,5ml, gastrine 0,5ml, hepatin 1ml. `,`2026-05-03`,`Consulta Medica`,`5606`,`5`,`220`,``),
(`25907`,`Presenta inflamaciÃ³n 3ra falange, presenta eritema, dolor, se extrajo levemente materia blanca, no cojea, se procede al cambio de trat. Tto amoxicla 0.3ml y dexa 0.3ml`,`2026-05-03`,`Consulta Medica`,`1580`,`5`,`80`,``),
(`25908`,`P: 23.350kg Presenta inflamaciÃ³n y eritema del rostro lado derecho, menciona el dueÃ±o que tiene jardÃ­n con espinas y abejas, presenta arcadas, trÃ¡quea no inflamada, pulmones limpios, deposiciones normales, se levanto decaÃ­do, se procede a tratar la reacciÃ³n alÃ©rgica Tto fortepen 2.3ml dexa 1.2ml`,`2026-05-03`,`Consulta Medica`,`273`,`5`,`90`,``),
(`25909`,`1er control, menciona q se lame demasiado donde se realizo la tricotomÃ­a para canalizar, la incisiÃ³n va bien, control el dÃ­a jueves 7`,`2026-05-04`,`Consulta Medica`,`5268`,`5`,`0`,``),
(`25910`,`se realizo control aun se observa proceso de cicatrizaciÃ³n se realizara control dÃ­a por medio `,`2026-05-04`,`Consulta Medica`,`5859`,`5`,`0`,``),
(`25911`,`P 5.250 kg vacuna Ã³ctuple vacuna rabia y desp. `,`2026-05-04`,`Consulta Medica`,`1714`,`5`,`200`,``),
(`25912`,`paciente presenta vÃ³mitos de color amarillo despuÃ©s de recibir su medicaciÃ³n se continua con la misma TTo gastrine 0.2 ml Hepa 0.8 ml x 2 dÃ­as VO hepadex 2 sobres uno por dÃ­a salame 100 gr x dÃ­a tambiÃ©n  recomienda cambio de alimento balanceado ya que la misma consume podium 
\nTratamiento 140 bs
\nsalame 40 bs
\nsobres 20 bs `,`2026-05-04`,`Consulta Medica`,`1584`,`5`,`200`,``),
(`25913`,`P 1.520 kg 1o vacuna triple felina de 2`,`2026-05-04`,`Consulta Medica`,`5802`,`5`,`100`,``),
(`25914`,`P 1.350 kg 1o vacuna triple felina de 2 `,`2026-05-04`,`Consulta Medica`,`5803`,`5`,`100`,``),
(`25915`,`BAÃ‘O Y CORTE`,`2026-05-04`,`Peluqueria`,`4370`,`5`,`90`,``),
(`25916`,`P 3.350 kg se observa paciente con ulcera en el ojo derecho se realizo la prueba de floresina observando la lesiÃ³n por traumatismo TTo bios ocuxina 1 gota c/ 8 hrs x 7 dÃ­as `,`2026-05-04`,`Consulta Medica`,`5566`,`5`,`200`,``),
(`25917`,`P 4.050 kg se observa paciente con corazÃ³n estable y pulmones limpios se alimenta de Matisse castrado y Gaty se recomienda cambio de alimentaciÃ³n a fino trato castrado exclusivamente se realizo corte de uÃ±as `,`2026-05-04`,`Consulta Medica`,`5868`,`5`,`50`,``),
(`25918`,`BaÃ±o y corte`,`2026-05-04`,`Peluqueria`,`5656`,`5`,`0`,``),
(`25919`,`P 2.900 kg paciente que llego a la paz el dÃ­a jueves 30 abril desde Santa Cruz el mismo con las siguientes vacunas dÃºplex 05/04/26 sÃ©xtuple 25/04/26 rabia 28/04/26 se realizara vacunaciÃ³n Ã³ctuple el 18 de mayo se observa corazÃ³n y pulmones estables y limpios `,`2026-05-04`,`Consulta Medica`,`5869`,`5`,`80`,``),
(`25920`,`P 4.450 kg vacuna rabia y desp. tos de perrera el 24 de mayo `,`2026-05-04`,`Consulta Medica`,`5671`,`5`,`100`,``),
(`25921`,`BaÃ±o y corte`,`2026-05-04`,`Peluqueria`,`4584`,`5`,`100`,``),
(`25922`,`BaÃ±o y corte`,`2026-05-04`,`Peluqueria`,`5872`,`5`,`120`,``),
(`25923`,`Peso 4,250Kg Vacuna anual triple felina, rabia y desparasitaciÃ³n `,`2026-05-04`,`Consulta Medica`,`5870`,`5`,`200`,``),
(`25924`,`Peso 3,250Kg Vacuna anual triple felina, rabia y desparasitaciÃ³n `,`2026-05-04`,`Consulta Medica`,`4608`,`5`,`200`,``),
(`25925`,`Peso 11,850Kg Vacuna anual Ã³ctuple rabia y desparasitaciÃ³n  Presenta cardiomegalia ,neumonÃ­a bilateral  se recomienda canitabs cardio `,`2026-05-04`,`Consulta Medica`,`4627`,`5`,`200`,``),
(`25926`,`Peso: 3.200kg. Paciente presenta inflamaciÃ³n en las encÃ­as. Gingivitis Tto: IM Keto 0.1ml, Ceft 0.3ml
\nTto: 200  `,`2026-05-04`,`Consulta Medica`,`5871`,`5`,`200`,``),
(`25927`,`Se observa mejoria, paciente ya no cojea al caminar, ya no existe absceso se coloca curavichera, en el Ã¡rea afectada Tto: IM Dexa 0.3ml, Amoxicla 0.3ml   
\nDebe 60bs del tratamiento del lunes y martes `,`2026-05-04`,`Consulta Medica`,`1580`,`5`,`60`,``),
(`25928`,`Peso calculado 15kg, Paciente presenta convulsiones por un periodo de mas de una hora observando rigidez en el cuello y disnea, en consultorio se determina intoxicaciÃ³n por posible Ã³rgano fosforado afectando sistema nervioso central Tto: Suero fisiolÃ³gico Novotioc 6ml, Midazolam 0.4ml, Dipirona 1.5ml, Rani 3ml, Suero Glucosado Hepatin 3ml, VO CarbÃ³n activado 3 comprimidos, IM Dexa 0.75 ml.  VO Hepadex 1 sobre 
\n
\nTto: 200bs
\nHepadex 1 sobre 10bs  `,`2026-05-04`,`Consulta Medica`,`5873`,`5`,`210`,``),
(`25929`,`buena evoluciÃ³n Tto Meloxi 0.2ml y Bplex 1ml, gomitas de colÃ¡geno 2 al dia `,`2026-05-04`,`Consulta Medica`,`3800`,`5`,`90`,``),
(`25930`,`se observa mejoria  Tto: gentamox 1.1ml,dipi 0,5ml, gastrine 0,5ml, hepatin 1ml.`,`2026-05-04`,`Consulta Medica`,`5606`,`5`,`0`,``),
(`25931`,`Paciente con asma cardiaco muy marcado se solicita nuevamente RX cardiaco y pulmonar para posterior medicaciÃ³n el miso realizo tratamiento con cardial 1/4 comp.diario el cual fue interrumpido por un periodo y retomo hace una semana `,`2026-05-05`,`Consulta Medica`,`3777`,`5`,`80`,``),
(`25932`,` paciente presenta vÃ³mitos de color blanco aun no hay apetito se sugiere cambio de alimentÃ³ a fino trato adulto 65 g diarios TTo gastrine 0.2 ml Hepa 0.8 m dipi 0.2 ml VO biogastrine 1 sobre x dÃ­a x 2 dÃ­as  `,`2026-05-05`,`Consulta Medica`,`1584`,`5`,`216`,``),
(`25933`,`peluqeuria y baÃ±o`,`2026-05-05`,`Peluqueria`,`854`,`5`,`100`,``),
(`25934`,`BaÃ±o y cepillado`,`2026-05-05`,`Peluqueria`,`4833`,`5`,`150`,``),
(`25935`,`baÃ±o y cepillado`,`2026-05-05`,`Consulta Medica`,`644`,`5`,`100`,``),
(`25936`,`P 4.700 kg 3o vacuna Ã³ctuple `,`2026-05-05`,`Consulta Medica`,`5804`,`5`,`100`,``),
(`25937`,`1Â° Control, buena evoluciÃ³n  jueves 07/05/2026 retiro de puntos  `,`2026-05-05`,`Consulta Medica`,`5717`,`5`,`0`,``),
(`25938`,`1|Â° Control buena evoluciÃ³n, jueves 07/05/2026 retiro de puntos  `,`2026-05-05`,`Consulta Medica`,`5716`,`5`,`0`,``),
(`25939`,`P 3.950 kg desp. interna y externa simparica trio corte de uÃ±as `,`2026-05-05`,`Consulta Medica`,`4800`,`5`,`130`,``),
(`25940`,`aun no hay cicatrizaciÃ³n continua con los puntos se realizara control dÃ­a por medio gomitas de colageno `,`2026-05-05`,`Consulta Medica`,`5866`,`5`,`30`,``),
(`25941`,`Corte y baÃ±o`,`2026-05-05`,`Peluqueria`,`3795`,`5`,`100`,``),
(`25942`,`P 24,700 kg T 39.3 paciente con deposiciones liquidas con melena desde el dÃ­a domingo el mismo se alimenta de cibau y patitas de pollo y pan se recomienda solo alimentaciÃ³n con croquetas TTo Gx 2.5 ml Dipi 1.2 ml  Rani 5 ml hepa 2 ml  VO espectryl 1 comp c/ 12 hrs x 3 dÃ­as gomitas de colÃ¡geno 
\ntratamiento 210 bs 
\ncomprimidos 72 bs
\ncolageno 30 bs `,`2026-05-05`,`Consulta Medica`,`5874`,`5`,`312`,``),
(`25943`,`se observa paciente con reacciÃ³n alÃ©rgica TTo atriben 1 ml gomitas de colageno  `,`2026-05-05`,`Consulta Medica`,`3713`,`5`,`110`,``),
(`25944`,`Tto: IM Keto 0.1ml, Ceft 0.3ml`,`2026-05-05`,`Consulta Medica`,`5871`,`5`,`0`,``),
(`25945`,`P 2.450 kg vacuna triple felina vacuna rabia y desp. `,`2026-05-05`,`Consulta Medica`,`5875`,`5`,`200`,``),
(`25946`,`P 4.550 kg se inicia plan de vacunas 1o octavalente de 3 `,`2026-05-05`,`Consulta Medica`,`5790`,`5`,`100`,``),
(`25947`,`23/04/2026 LD perdida de 1 pieza X 0.7 ml keto 0.3 ml A 0.2 ml IM ceftriaxona 0.9 ml keto 0.2 ml `,`2026-05-05`,`Consulta Medica`,`5074`,`5`,`220`,``),
(`25948`,`se observa paciente con sangrado en las aftas de la boca del calicivirus TTo violeta de genciana todos los dÃ­as `,`2026-05-05`,`Consulta Medica`,`1794`,`5`,`0`,``),
(`25949`,`se observa mejoria  se usa quemacuran crema Tto: IM Dexa 0.3ml, Amoxicla 0.3ml`,`2026-05-05`,`Consulta Medica`,`1580`,`5`,`60`,``),
(`25950`,`P 21.700kg se observa herida por mordedura en flanco derecho cerca del MPD  se realizo curaciÃ³n del Ã¡rea se realiza cicatrizaciÃ³n con quemacuran crema TTo amoxicla 1 ml dexa 1 ml gomitas de colÃ¡geno  `,`2026-05-05`,`Consulta Medica`,`3275`,`5`,`230`,``),
(`25951`,`0.430 kg se realiza desp. vermic total `,`2026-05-05`,`Consulta Medica`,`5864`,`5`,`50`,``),
(`25952`,`Peso:18.550kg. Paciente presenta alergia crÃ³nica generalizada por deficiencia nutricional ya que se alimenta de carne huesos arroz brÃ³coli y zanahoria se solicita raspad cutÃ¡neo y antibiograma (se sugiere tambiÃ©n realizar quÃ­mica sanguÃ­nea) TTo Atriben  0.6 ml`,`2026-05-06`,`Consulta Medica`,`234`,`5`,`90`,``),
(`25953`,`P:2.780kg Presenta Gengivitis, es gato techero, menciona que le realizaron la limpieza dental en enero, solo tiene la vacuna de la rabia, no se esta acicalando, presenta una masa bucal lado derecho, se manda orden de laboratorio calicivirus, herpes felino y leucemia felina 
\nse cobro de la prueba solamente`,`2026-05-06`,`Consulta Medica`,`5877`,`5`,`80`,``),
(`25954`,`P:12.550kg Presenta sobrepeso, el dueÃ±o menciona que se atoro la pata en un rendija de una banca, presenta inflamaciÃ³n en la rodilla derecha, alimentaciÃ³n casera, antes le daban Podium, presenta periodontitis, presenta artrosis MP, presenta pÃ©nfigo ala altura de lumbar dorsal, a palpaciÃ³n presenta dos masas a la altura de la sacra lados izquierdo y derecho se pide estar bajo observaciÃ³n si crece, Tto meloxicam 0.5ml y Bplex 1 
\nTratamiento de 2 dias`,`2026-05-06`,`Consulta Medica`,`5876`,`5`,`150`,``),
(`25955`,`P:2.600kg  octuple (3-3)`,`2026-05-06`,`Consulta Medica`,`5808`,`5`,`100`,``),
(`25956`,`A la  palpaciÃ³n  se observa remisiÃ³n completa de ambas masas.`,`2026-05-06`,`Consulta Medica`,`270`,`5`,`0`,``),
(`25957`,`Llego a casa  hace 4 dÃ­as. fue encontrada en un edificio vacÃ­o, come croquetas de gatito bebe, Presenta una malformaciÃ³n en miembro anterior derecho, 1Â° Triple Felina Peso 1.060 Kg`,`2026-05-06`,`Consulta Medica`,`5878`,`5`,`100`,``),
(`25958`,`paciente con vÃ³mitos y falta de apetito se suspende antibiÃ³tico se realiza suero terapia TTo IV ringer lactato Rexilen 1 ml Rani 1 ml dipi 0.2 ml Suero glucosado hepa 1 ml continua con biogastrine y cremas `,`2026-05-06`,`Consulta Medica`,`1584`,`5`,`120`,``),
(`25959`,`baÃ±o y corte`,`2026-05-06`,`Peluqueria`,`1691`,`5`,`100`,``),
(`25960`,`control, falta un poco cicatrizar`,`2026-05-06`,`Consulta Medica`,`5859`,`5`,`0`,``),
(`25961`,`se observa mejoria ya no hay deposiciones liquidas con presencia de melena TTo Gx 2.5 ml Dipi 1.2 ml Rani 5 ml hepa 2 ml `,`2026-05-06`,`Consulta Medica`,`5874`,`5`,`0`,``),
(`25962`,`P: 23.350kg paciente con uÃ±a rota en MPI se realizo el limado de la uÃ±a y curavichera plata TT meloxican 0.9 ml `,`2026-05-06`,`Consulta Medica`,`273`,`5`,`90`,``),
(`25963`,`P 14.100 kg alimento fino trato adulto 150 kg x dia `,`2026-05-06`,`Consulta Medica`,`651`,`5`,`190`,``),
(`25964`,`Peso:4.300kg paciente con presencia de sarro en las muelas y Gengivitis se sugiere LD urgente TTo ceftriaxona 0.4 ml keto 0.1 ml 
\ntratamiento 140 bs 
\nLD 200 bs `,`2026-05-06`,`Consulta Medica`,`5879`,`5`,`170`,``),
(`25965`,`P 3.400 kg se observa en RX cardiomegalia marcada y pulmones marcados con secuelas de proceso respiratorio antiguo TTo cardial 1/4 comp. x dÃ­a dexa 1/4 comp x dÃ­a x 12 dÃ­as Canitab cardio 1comp x dÃ­a x 10 dÃ­as `,`2026-05-06`,`Consulta Medica`,`3777`,`5`,`139`,``),
(`25966`,` Se observa mejoria se sugiere LD pronto Tto: IM Keto 0.1ml, Ceft 0.3ml`,`2026-05-06`,`Consulta Medica`,`5871`,`5`,`0`,``),
(`25967`,`Corte de uÃ±as `,`2026-05-06`,`Consulta Medica`,`5740`,`5`,`30`,``),
(`25968`,`P 6.150 kg dosis mensual artrossan 0.3 ml  `,`2026-05-06`,`Consulta Medica`,`5235`,`5`,`120`,``),
(`25969`,`alimento hepatic 110 g x dia `,`2026-05-06`,`Consulta Medica`,`3136`,`5`,`230`,``),
(`25970`,` TTo amoxicla 1 ml dexa 1 ml 2 gomitas de colÃ¡geno  `,`2026-05-06`,`Consulta Medica`,`3275`,`5`,`60`,``),
(`25971`,`se solicita RX del Miembro anterior Izquierdo  ya q se sospecha de una dislocaciÃ³n `,`2026-05-06`,`Consulta Medica`,`3800`,`5`,`0`,``),
(`25972`,`31/05/2025 Vacuna anual octuple, rabia y desparasirtacion `,`2026-05-06`,`Consulta Medica`,`3276`,`5`,`200`,``),
(`25973`,`31/05/2025 Vacuna anual octuple, rabia y desparasirtacion `,`2026-05-06`,`Consulta Medica`,`3275`,`5`,`200`,``),
(`25974`,`Camada de 10 cachorros de los cuales murieron dos , actualmente son ocho cachorros de los cuales  tres son de pelaje negro presentan inflamaciÃ³n en los ganglios linfÃ¡ticos y cinco son de pelaje dorados dos de ellos presentan inflaciÃ³n en los ganglios linfÃ¡ticos , de los cuales uno Cachorro de 16 dÃ­as de nacido con inflamaciÃ³n en ganglio linfÃ¡tico con presencia de pus, ritmo cardiaco bajo, temperatura baja y deficiencia respiratoria baja, se realiza oxigeno terapia, VivirÃ¡n 0.01ml sub lingual `,`2026-05-06`,`Consulta Medica`,`5781`,`5`,`100`,``),
(`25975`,`P 1.500kg  se observa paciente con desgaste articular por artrosis y dolor TTo meloxican 0.06 ml VO artiflex jarabe 2.5 ml x dia corte de uÃ±as `,`2026-05-06`,`Consulta Medica`,`3227`,`5`,`320`,``),
(`25976`,`P 4.800 kg avulsion ungueal (desprendimiento de la uÃ±a) MAI, se procediÃ³ a sacar el resto y cauterizar por sangrado, se procede a vendar Tto meloxi 0.2ml, Cuagulomax 0.2ml`,`2026-05-07`,`Consulta Medica`,`4779`,`5`,`120`,``),
(`25977`,`TTo ceftriaxona 0.4 ml keto 0.1 ml, se programa cirugÃ­a viernes 8`,`2026-05-07`,`Consulta Medica`,`5879`,`5`,`0`,``),
];

async function ejecutarMigracion() {
    console.log(`🚀 Iniciando carga en historial_v2...`);

    for (let registro of sqlData) {
        const [id_h, descripcion, fecha, tipo, id_c, sesion, precio] = registro;

        try {
            // Intentar obtener datos extra del cliente
            const clienteRef = await db.collection('clientes').where('id_cliente', '==', id_c.toString()).get();
            let c = {};
            if (!clienteRef.empty) {
                c = clienteRef.docs[0].data();
            }

            // Procesar fecha
            let fechaDate = new Date();
            if (fecha && fecha !== `0000-00-00`) {
                const parts = fecha.split('-');
                fechaDate = new Date(parts[0], parts[1] - 1, parts[2]);
            }

            const nuevoHistorial = {
                ci: c.ci || ``,
                color: c.color || `N/A`,
                correo: c.correo || ``,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                descripcion: corregirTexto(descripcion),
                direccion: c.direccion || ``,
                especie: c.especie || ``,
                fecha_registro: admin.firestore.Timestamp.fromDate(fechaDate),
                fechanac: c.fechanac || ``,
                id_cliente: id_c.toString(),
                nombre_dueno: c.nombre_dueno || c.nombre || `Sin nombre`,
                nombre_mascota: c.nombre_mascota || `Desconocido`,
                precioh: parseInt(precio) || 0,
                raza: c.raza || ``,
                sexo: c.sexo || ``,
                telefono: c.telefono || ``,
                tipo_historial: tipo || `Consulta Medica`
            };

            await db.collection('historial_v2').doc(id_h.toString()).set(nuevoHistorial);
            console.log(`✅ ID ${id_h} migrado correctamente.`);

        } catch (err) {
            console.error(`❌ Error en ID ${id_h}:`, err.message);
        }
    }
    console.log(`🏁 Proceso finalizado.`);
}

function corregirTexto(texto) {
    if (!texto) return ``;
    try {
        // Esto limpia los símbolos raros del SQL (Ã³, Â°, etc)
        return Buffer.from(texto, 'latin1').toString('utf8');
    } catch (e) {
        return texto;
    }
}

ejecutarMigracion();