import 'dart:developer';

import 'package:eshop_multivendor/Helper/Color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

import '../../../Model/Section_Model.dart';

extraDesc(Product model, BuildContext context) {
  return model.desc!= null
      ? Card(
          child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10),
              child: Column(
                children: [
                  Text('Product Description',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'Ubuntu',
              fontStyle: FontStyle.normal,
              color: Theme.of(context).colorScheme.fontColor,
            ),),
            HtmlWidget(
                    model.desc??'',
                    textStyle:
                        TextStyle(color: Theme.of(context).colorScheme.fontColor),
                  ),
                ],
              )),
        )
      : const SizedBox();
}
