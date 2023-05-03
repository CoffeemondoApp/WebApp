import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart';
import 'dart:js' as js;
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_launcher_icons/xml_templates.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:mercadopago_sdk/mercadopago_sdk.dart';

import 'package:webviewx/webviewx.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:image_network/image_network.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps/google_maps.dart' as gmaps;
import 'package:intl/intl.dart';

class crearEventoUI extends StatefulWidget {
  final tipoUI;
  const crearEventoUI({required this.tipoUI});

  @override
  _crearEventoUIState createState() => _crearEventoUIState();
}

class _crearEventoUIState extends State<crearEventoUI> {
  var colorScaffold = Color(0xffffebdcac);
  var colorNaranja = Color.fromARGB(255, 255, 79, 52);
  var colorMorado = Color.fromARGB(0xff, 0x52, 0x01, 0x9b);
  //Modulo VisionAI
  var mostrarControl = false;
  var mostrarControl2 = false;
  var mostrarData = false;
  var mostrarData2 = false;
  var mostrarDataStudio = false;
  var mostrarNombre = false;
  var mostrarNombre2 = false;
  var uidCamara = "";
  var pantalla = 0.0;
  var resenasGuardadas = [];
  var resenasKeys = [];
  var listaResenas = [];

  TextEditingController cafeteriaController = TextEditingController();
  TextEditingController lugarController = TextEditingController();
  TextEditingController nombreEventoController = TextEditingController();
  TextEditingController descripcionController = TextEditingController();
  TextEditingController ubicacionController = TextEditingController();
  TextEditingController fechasEventoController = TextEditingController();
  TextEditingController capacidadMaxController = TextEditingController();
  TextEditingController precioController = TextEditingController();

  var tarjetaScrolled = false;

  var dispositivo = '';

  var esLugar = false;

  var btnResenaHovered = ['', false];

  FirebaseFirestore firestore = FirebaseFirestore.instance;

  //Obtengo toda la informacion de la coleccion reseñas
  CollectionReference _collectionRef =
      FirebaseFirestore.instance.collection('resenas');

  Future<List<Map<String, dynamic>>> getResenasData() async {
    User? user = FirebaseAuth.instance.currentUser;

    QuerySnapshot resenasQuerySnapshot = await _collectionRef.get();
    List<Map<String, dynamic>> resenasDataList = [];
    for (var doc in resenasQuerySnapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      resenasDataList.add({'data': data, 'uid': doc.id});
    }

    setState(() {
      listaResenas = resenasDataList;
    });
    return resenasDataList;
  }

  Future<List<dynamic>> getResenasKeys() async {
    User? user = FirebaseAuth.instance.currentUser;

    QuerySnapshot resenasQuerySnapshot = await _collectionRef.get();
    var resenasKeysList = [];
    for (var doc in resenasQuerySnapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      widget.tipoUI == 'Mis reseñas'
          ? (data['uid_usuario'] == user?.uid)
              ? {
                  resenasKeysList.add([data, doc.id])
                }
              : null
          : resenasKeysList.add([data, doc.id]);
    }
    setState(() {
      resenasKeys = resenasKeysList;
    });
    return resenasKeysList;
  }

  final CarouselController _controller = CarouselController();

  String nombreResenaActual = "";

  Future<void> _openMapsModal(String ubicacion) async {
    final String googleMapsUrl =
        "https://www.google.com/maps/search/?api=1&query=$ubicacion";
    if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
      await launchUrl(Uri.parse(googleMapsUrl));
    } else {
      throw "Could not launch $googleMapsUrl";
    }
  }

  final Random random = Random();
  static const chars =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';

  String generateRandomString(chars, int length) =>
      Iterable.generate(length, (idx) => chars[random.nextInt(chars.length)])
          .join();

  List<String> constructorTickets(int cantEntradas, int dias) {
    //generar strings random que solo contengan numeros y letras mayusculas y minusculas y que no se repitan
    List<String> tickets = [];
    for (var i = 0; i < cantEntradas * dias; i++) {
      tickets.add(generateRandomString(chars, 20));
    }
    return tickets;
  }

  void generarTickets(String uidEvento, int cantEntradas, int dias) {
    try {
      // Importante: Este tipo de declaracion se utiliza para solamente actualizar la informacion solicitada y no manipular informacion adicional, como lo es la imagen y esto permite no borrar otros datos importantes

      // Se busca la coleccion 'users' de la BD de Firestore en donde el uid sea igual al del usuario actual
      final DocumentReference docRef =
          FirebaseFirestore.instance.collection("eventos").doc(uidEvento);

      docRef.update({'tickets': constructorTickets(cantEntradas, dias)});
      print('Se han creado de forma exitosa los ' +
          (cantEntradas * dias).toString() +
          ' tickets para el evento ' +
          uidEvento);
      // Una vez actualizada la informacion, se devuelve a InfoUser para mostrar su nueva informacion
    } catch (e) {
      print("Error al intentar ingresar informacion");
    }
  }

  final Map<String, Object> preference = {
    'items': [
      {
        'title': 'Test Product',
        'description': 'Description',
        'quantity': 3,
        'currency_id': 'ARS',
        'unit_price': 1500,
      }
    ],
    'payer': {'name': 'Buyer G.', 'email': 'test@gmail.com'},
  };

  Widget btnResena(
      IconData icono, String tipo, String nombre, String UidResena) {
    return (InkWell(
      onHover: (value) {
        if (value) {
          setState(() {
            btnResenaHovered = [tipo, true];
          });
        } else {
          setState(() {
            btnResenaHovered = [tipo, false];
          });
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: (btnResenaHovered[0] == tipo &&
                  btnResenaHovered[1] == true &&
                  nombreResenaActual == nombre)
              ? Color.fromARGB(255, 107, 0, 200)
              : colorMorado,
          borderRadius: BorderRadius.all(
            Radius.circular(50),
          ),
        ),
        child: Container(
          margin: EdgeInsets.all(10),
          child: Icon(icono, color: colorNaranja, size: 26),
        ),
      ),
    ));
  }

  String obtenerKeyResena(String nombre) {
    String keyResena = '';
    for (var resena in resenasKeys) {
      if (resena[0]['nickname_usuario'] == nombre) {
        keyResena = resena[1];
      }
    }
    return keyResena;
  }

  double promedio(Map<String, dynamic> listaCalificaciones) {
    double promedio = 0;
    double suma = 0;
    int cantidad = 0;
    listaCalificaciones.forEach((key, value) {
      suma += value;
      cantidad++;
    });
    promedio = suma / cantidad;
    return promedio;
  }

  var textoPregunta = [
    '¿Cómo describirías la atmósfera de la cafetería?',
    '¿Cómo describirías la comida y bebidas que ofrecen?',
    '¿Qué tan rápido y eficiente es el servicio de meseros?',
    '¿El precio de los productos es justo por su calidad?',
    '¿Qué tan frecuentemente visitarías la cafetería nuevamente?',
    '¿Recomendarías la cafetería a amigos y familiares?',
    '¿Qué tan accesible es la ubicación de la cafetería?',
    '¿El personal es amable y servicial?',
    '¿La cafetería ofrece opciones para personas con necesidades alimentarias especiales?',
    '¿Estás satisfecho con la experiencia en general en la cafetería?'
  ];

  List<DropdownMenuItem<Object>> nombresCafeterias = [];
  var ubicacionesCafeterias = [];
  //funcion para obtener la coleccion de cafeterias desde la base de datos y convertirlas en List<DropdownMenuItem<Object>>
  Future<void> generarListaCafeterias() async {
    List<DropdownMenuItem<Object>> listaCafeterias = [];

    await FirebaseFirestore.instance
        .collection('cafeterias')
        .get()
        .then((QuerySnapshot querySnapshot) {
      querySnapshot.docs.forEach((doc) {
        setState(() {
          ubicacionesCafeterias.add({
            'ubicacion': doc['ubicacion'],
            'id': doc.id
          }); //se agrega el nombre y el id de la cafeteria a la lista
        });
        listaCafeterias.add(DropdownMenuItem(
          value: doc.id,
          child: Text(doc['nombre']),
        ));
      });
    });
    setState(() {
      nombresCafeterias = listaCafeterias;
    });
  }

  String obtenerUbicacionCafeteria(String idCafeteria) {
    String ubicacion = '';
    for (var cafeteria in ubicacionesCafeterias) {
      if (cafeteria['id'] == idCafeteria) {
        ubicacion = cafeteria['ubicacion'];
      }
    }
    return ubicacion;
  }

  Widget textFieldSelectCafeteria(TextEditingController controller) {
    return (Container(
      margin: EdgeInsets.only(top: 20),
      width: 500,
      height: 90,
      child: DropdownButtonFormField(
          style: TextStyle(color: colorNaranja, fontSize: 18),
          enableFeedback: !esLugar,
          validator: (value) {
            if (value == null) {
              return 'Por favor selecciona una cafeteria';
            }
            return null;
          },
          icon: Icon(Icons.arrow_drop_down_outlined,
              color: !esLugar ? colorNaranja : Colors.grey, size: 24),
          borderRadius: BorderRadius.all(Radius.circular(20)),
          isExpanded: true,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.place,
                color: !esLugar ? colorNaranja : Colors.grey, size: 24),
            hintText: "Seleccionar cafeteria del evento",
            hintStyle: TextStyle(
              color: !esLugar ? colorNaranja : Colors.grey,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(
                color: !esLugar
                    ? colorNaranja
                    : Colors.grey, // Aquí puedes asignar el color que desees
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(
                  color: !esLugar ? colorNaranja : Colors.grey,
                  width: 2 // Aquí puedes asignar el color que desees
                  ),
            ),
          ),
          dropdownColor: colorMorado,
          items: nombresCafeterias,
          onChanged: esLugar
              ? null
              : (value) {
                  //poner en el controller de ubicacion el nombre de la cafeteria
                  setState(() {
                    ubicacionController.text =
                        obtenerUbicacionCafeteria(value.toString());
                  });
                }),
    ));
  }

  Widget textFieldInputLugar(TextEditingController controller) {
    return (Container(
      width: 500,
      child: TextFormField(
        enabled: esLugar,
        controller: controller,
        style: TextStyle(color: colorNaranja, fontSize: 18),
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.place,
              color: esLugar ? colorNaranja : Colors.grey, size: 24),
          hintText: "Ingresar lugar del evento",
          hintStyle: TextStyle(
            color: esLugar ? colorNaranja : Colors.grey,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(
              color: colorNaranja, // Aquí puedes asignar el color que desees
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(
                color: colorNaranja,
                width: 2 // Aquí puedes asignar el color que desees
                ),
          ),
        ),
      ),
    ));
  }

  Widget textFieldNombreEvento(TextEditingController controller) {
    return (Container(
      width: 600,
      child: TextFormField(
        controller: controller,
        style: TextStyle(color: colorNaranja, fontSize: 18),
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.event, color: colorNaranja, size: 24),
          hintText: "Nombre del evento",
          hintStyle: TextStyle(
            color: colorNaranja,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(
              color: colorNaranja, // Aquí puedes asignar el color que desees
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(
                color: colorNaranja,
                width: 2 // Aquí puedes asignar el color que desees
                ),
          ),
        ),
      ),
    ));
  }

  Widget switchCafeteriaLugar() {
    return (Switch(
        value: esLugar,
        onChanged: (value) {
          setState(() {
            esLugar = value;
            value ? cafeteriaController.clear() : lugarController.clear();
            ubicacionController.clear();
          });
        },
        activeTrackColor: colorNaranja,
        activeColor: colorNaranja,
        inactiveTrackColor: colorNaranja,
        inactiveThumbColor: colorNaranja));
  }

  String cambiarFormatoFecha(DateTimeRange fecha) {
    String fechaInicio = DateFormat('dd/MM/yyyy').format(fecha.start);
    String fechaFin = DateFormat('dd/MM/yyyy').format(fecha.end);
    return fechaInicio + ' - ' + fechaFin;
  }

  String transformarFechas(DateTime fecha_in, DateTime fecha_fin) {
    var fechaModificada = '';
    if (fecha_in.month == fecha_fin.month) {
      fechaModificada = 'Desde el ' +
          fecha_in.day.toString() +
          ' al ' +
          fecha_fin.day.toString() +
          ' de ' +
          //Obtener nombre del mes
          DateFormat.MMMM('es').format(fecha_in);
    } else {
      fechaModificada = 'Desde el ' +
          fecha_in.day.toString() +
          ' de ' +
          //Obtener nombre del mes
          DateFormat.MMMM('es').format(fecha_in) +
          ' al ' +
          fecha_fin.day.toString() +
          ' de ' +
          //Obtener nombre del mes
          DateFormat.MMMM('es').format(fecha_fin);
    }

    return fechaModificada;
  }

  Widget textFieldFechaEvento(TextEditingController controller) {
    return (Container(
      width: 500,
      child: TextFormField(
        readOnly: true,
        onTap: () async {
          DateTimeRange? pickeddate = await showDateRangePicker(
              locale: const Locale("es", "CL"),
              context: context,
              //initialDate: DateTime.now(),

              firstDate: DateTime(2023),
              lastDate: DateTime(2025),
              builder: (context, child) {
                return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        // or dark
                        primary: colorNaranja,
                        onPrimary: colorMorado,
                        surface: colorNaranja,
                        onSurface: Colors.black,

                        background: colorNaranja,
                        onBackground: Colors.black,

                        error: colorNaranja,
                        onError: colorMorado,
                        secondary: colorNaranja,
                        onSecondary: Colors.black,

                        primaryVariant: colorNaranja,
                        secondaryVariant: colorNaranja,
                      ),
                      textButtonTheme: TextButtonThemeData(
                        style: TextButton.styleFrom(
                          primary: colorMorado, // button text color
                        ),
                      ),
                    ),
                    child: Container(
                      margin: EdgeInsets.symmetric(
                          horizontal: MediaQuery.of(context).size.width * 0.3,
                          vertical: MediaQuery.of(context).size.height * 0.1),
                      child: child!,
                    ));
              });

          if (pickeddate != null) {
            //Cambiar formato de daterangepicker a dd/mm/yyyy
            var fecha_cambiada = cambiarFormatoFecha(pickeddate);
            var fecha_evento = fecha_cambiada.split(' - ');
            var fecha_evento_inicio = fecha_evento[0].split(' ');
            var fecha_evento_fin = fecha_evento[1].split(' ');
            print(fecha_evento_inicio[0] + ' / ' + fecha_evento_fin[0]);
            setState(() {
              controller.text =
                  transformarFechas(pickeddate.start, pickeddate.end);
            });
          }
        },
        controller: controller,
        style: TextStyle(color: colorNaranja, fontSize: 18),
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.date_range, color: colorNaranja, size: 24),
          hintText: "Fecha/s del evento",
          hintStyle: TextStyle(
            color: colorNaranja,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(
              color: colorNaranja, // Aquí puedes asignar el color que desees
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(
                color: colorNaranja,
                width: 2 // Aquí puedes asignar el color que desees
                ),
          ),
        ),
      ),
    ));
  }

  Widget textFieldDescripcion(TextEditingController controller) {
    return (Container(
      width: 600,
      child: TextFormField(
        maxLines: null,
        minLines: 4,
        maxLength: 120,
        //controller: nombreEventoController,
        style: TextStyle(color: colorNaranja, fontSize: 18),
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.description, color: colorNaranja, size: 24),
          hintText: "Descripción del evento",
          hintStyle: TextStyle(
            color: colorNaranja,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(
              color: colorNaranja, // Aquí puedes asignar el color que desees
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(
                color: colorNaranja,
                width: 2 // Aquí puedes asignar el color que desees
                ),
          ),
        ),
      ),
    ));
  }

  Widget textFieldUbicacion(TextEditingController controller) {
    return (TextFormField(
      onTap: () {},
      controller: controller,
      style: TextStyle(color: colorNaranja, fontSize: 18),
      decoration: InputDecoration(
        prefixIcon:
            Icon(Icons.location_city_outlined, color: colorNaranja, size: 24),
        hintText: "Ubicacion del evento",
        hintStyle: TextStyle(
          color: colorNaranja,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: colorNaranja, // Aquí puedes asignar el color que desees
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
              color: colorNaranja,
              width: 2 // Aquí puedes asignar el color que desees
              ),
        ),
      ),
    ));
  }

  Widget textFieldImagenes() {
    return (TextFormField(
      //controller: nombreEventoController,
      style: TextStyle(color: colorNaranja, fontSize: 18),
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.image, color: colorNaranja, size: 24),
        hintText: "Imagen del evento",
        hintStyle: TextStyle(
          color: colorNaranja,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: colorNaranja, // Aquí puedes asignar el color que desees
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
              color: colorNaranja,
              width: 2 // Aquí puedes asignar el color que desees
              ),
        ),
      ),
    ));
  }

  Widget textFieldCapacidadMax(TextEditingController controller) {
    return (Container(
        width: 300,
        child: TextFormField(
          //controller: nombreEventoController,
          style: TextStyle(color: colorNaranja, fontSize: 18),
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.groups, color: colorNaranja, size: 24),
            hintText: "Capacidad maxima",
            suffix: Text('Personas', style: TextStyle(color: colorNaranja)),
            hintStyle: TextStyle(
              color: colorNaranja,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(
                color: colorNaranja, // Aquí puedes asignar el color que desees
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(
                  color: colorNaranja,
                  width: 2 // Aquí puedes asignar el color que desees
                  ),
            ),
          ),
        )));
  }

  Widget textFieldPrecio(TextEditingController controller) {
    return (Container(
        width: 300,
        child: TextFormField(
          //controller: nombreEventoController,
          style: TextStyle(color: colorNaranja, fontSize: 18),
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.attach_money_outlined,
                color: colorNaranja, size: 24),
            hintText: "Valor entradas",
            suffix: Text('Pesos', style: TextStyle(color: colorNaranja)),
            hintStyle: TextStyle(
              color: colorNaranja,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(
                color: colorNaranja, // Aquí puedes asignar el color que desees
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(
                  color: colorNaranja,
                  width: 2 // Aquí puedes asignar el color que desees
                  ),
            ),
          ),
        )));
  }

  Widget textFieldSepararEntradas(TextEditingController controller) {
    return (Container(
        width: 300,
        child: TextFormField(
          //controller: nombreEventoController,
          style: TextStyle(color: colorNaranja, fontSize: 18),
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.confirmation_num_outlined,
                color: colorNaranja, size: 24),
            hintText: "Ingrese entradas por separar",
            hintStyle: TextStyle(
              color: colorNaranja,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(
                color: colorNaranja, // Aquí puedes asignar el color que desees
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(
                  color: colorNaranja,
                  width: 2 // Aquí puedes asignar el color que desees
                  ),
            ),
          ),
        )));
  }

  final numberFormat = NumberFormat.currency(
      locale: 'es_MX', symbol: "\$", name: "Pesos", decimalDigits: 0);

  Widget dashboardComercial() {
    return (Container(
      margin: EdgeInsets.only(top: 40),
      width: 350,
      height: 200,
      decoration: BoxDecoration(
        color: colorMorado,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 30, horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ingresos estimados: ',
                  style: TextStyle(
                    color: colorNaranja,
                    fontSize: 18,
                    //fontWeight: FontWeight.bold
                  ),
                ),
                Text(
                  numberFormat.format(2045678),
                  style: TextStyle(
                      color: colorNaranja,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                )
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Comision(1%): ',
                  style: TextStyle(
                    color: colorNaranja,
                    fontSize: 18,
                    //fontWeight: FontWeight.bold
                  ),
                ),
                Text(
                  numberFormat.format((2045678 * 0.1)),
                  style: TextStyle(
                      color: colorNaranja,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                )
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ingresos Neto: ',
                  style: TextStyle(
                    color: colorNaranja,
                    fontSize: 18,
                    //fontWeight: FontWeight.bold
                  ),
                ),
                Text(
                  numberFormat.format(2045678 - (2045678 * 0.1)),
                  style: TextStyle(
                      color: colorNaranja,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                )
              ],
            )
          ],
        ),
      ),
    ));
  }

  Widget vistaCrearEvento() {
    Future.delayed(Duration(seconds: 1), () {
      setState(() {
        mostrarDataStudio = true;
      });
    });

    return Container(
        height: MediaQuery.of(context).size.height - 180,
        //color: Colors.blue,
        child: Container(
          margin: EdgeInsets.only(left: 70, right: 70, top: 50),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  textFieldNombreEvento(nombreEventoController),
                  textFieldFechaEvento(fechasEventoController),
                ],
              ),
              SizedBox(
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  textFieldSelectCafeteria(cafeteriaController),
                  switchCafeteriaLugar(),
                  textFieldInputLugar(lugarController)
                ],
              ),
              const SizedBox(
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  textFieldDescripcion(descripcionController),
                  Container(
                    width: 500,
                    height: 135,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        textFieldUbicacion(ubicacionController),
                        textFieldImagenes(),
                      ],
                    ),
                  ),
                ],
              ),
              Container(
                margin: EdgeInsets.only(top: 40, bottom: 20),
                height: 3,
                decoration: BoxDecoration(
                  color: colorMorado,
                  borderRadius: BorderRadius.circular(80),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  textFieldCapacidadMax(capacidadMaxController),
                  textFieldPrecio(precioController),
                  textFieldSepararEntradas(precioController)
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  dashboardComercial(),
                  Container(
                    margin: EdgeInsets.only(top: 40),
                    width: 750,
                    height: 200,
                    decoration: BoxDecoration(
                      color: colorNaranja,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(),
                  )
                ],
              )
            ],
          ),
        ));
  }

  String obtenerNombreUser(String uid) {
    var retorno = '';
    listaResenas.forEach((resena) {
      if (uid == resena['uid']) {
        retorno = resena['data']['nickname_usuario'];
      }
    });

    return retorno;
  }

  Widget vistaWeb() {
    return (Dialog(
      backgroundColor: Color.fromARGB(0, 0, 0, 0),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOutBack,
        height: MediaQuery.of(context).size.height - 50,
        width: 1280,
        decoration: BoxDecoration(
            color: colorScaffold,
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                spreadRadius: 5,
                blurRadius: 7,
                offset: Offset(0, 3), // changes position of shadow
              ),
            ]),
        child: Container(
            margin: EdgeInsets.only(
                top: 50,
                left: dispositivo == 'PC' ? 0 : 0,
                right: dispositivo == 'PC' ? 0 : 0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                    width: MediaQuery.of(context).size.width * 0.6,
                    height: 70,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(40),
                        color: colorNaranja,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            spreadRadius: 5,
                            blurRadius: 7,
                            offset: Offset(0, 3), // changes position of shadow
                          ),
                        ]),
                    child: Stack(
                      children: [
                        Center(
                            child: Text(
                          'Crear evento',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        )),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 500),
                            curve: Curves.easeInOutBack,
                            width: mostrarData ? 250 : 80,
                            height: 70,
                            decoration: BoxDecoration(
                                color: colorMorado,
                                borderRadius: BorderRadius.circular(40)),
                            child: GestureDetector(
                              onTap: (() {
                                print(listaResenas);
                                setState(() {
                                  mostrarData = !mostrarData;

                                  mostrarControl2 = false;
                                });
                                Future.delayed(
                                    Duration(
                                        milliseconds: mostrarData2 ? 50 : 550),
                                    () {
                                  setState(() {
                                    mostrarData2 = !mostrarData2;
                                    mostrarControl = false;
                                  });
                                });
                              }),
                              child: mostrarData2
                                  ? Center(
                                      child: Text(
                                        'Eventos',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                  : Icon(
                                      Icons.event,
                                      color: colorNaranja,
                                      size: 50,
                                    ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 500),
                            curve: Curves.easeInOutBack,
                            width: 250,
                            height: 70,
                            decoration: BoxDecoration(
                                color: colorMorado,
                                borderRadius: BorderRadius.circular(40)),
                            child: GestureDetector(
                                child: Center(
                              child: Text(
                                widget.tipoUI == 'Reseñas guardadas' &&
                                        resenasGuardadas.isEmpty
                                    ? ''
                                    : obtenerNombreUser(nombreResenaActual),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )),
                          ),
                        ),
                      ],
                    )),
                Container(child: vistaCrearEvento()),
              ],
            )),
      ),
    ));
  }

  Widget vistaMobile() {
    return (AnimatedContainer(
      duration: Duration(milliseconds: 500),
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      decoration: BoxDecoration(color: colorScaffold),
      child: Container(
        margin: EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                  color: colorMorado,
                  borderRadius: BorderRadius.all(Radius.circular(20))),
              child: Container(
                margin: EdgeInsets.symmetric(vertical: 5, horizontal: 20),
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  child: Text(
                    'Todas las reseñas',
                    style: TextStyle(
                        color: colorNaranja,
                        fontWeight: FontWeight.bold,
                        fontSize: 24),
                  ),
                ),
              ),
            ),
            Container(
              alignment: Alignment.topCenter,
              margin: EdgeInsets.symmetric(vertical: 20),
              decoration:
                  BoxDecoration(borderRadius: BorderRadius.circular(20)),
              //child: sliderImagenes(),
            ),
          ],
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final ancho_pantalla = MediaQuery.of(context).size.width;
    setState(() {
      pantalla = ancho_pantalla;
    });

    setState(() {
      if (ancho_pantalla > 1130) {
        dispositivo = 'PC';
      } else {
        dispositivo = 'MOVIL';
      }
    });
    return (dispositivo == 'PC') ? vistaWeb() : vistaMobile();
  }

  @override
  void initState() {
    super.initState();
    generarListaCafeterias();
  }
}
