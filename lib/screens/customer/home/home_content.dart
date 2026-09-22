import 'package:flutter/material.dart';

/// Editorial collections are independent of catalog records and navigation.
class HomeCollection {
  final String title;
  final String query;
  final String image;
  final List<Color> labelColors;
  const HomeCollection(
      {required this.title,
      required this.query,
      required this.image,
      required this.labelColors});
}

const homeCategories = [
  HomeCollection(
      title: 'ورد وبوكيهات',
      query: 'الزهور',
      image: 'assets/images/product_bouquet.png',
      labelColors: [Color(0xFFDDF4F0), Color(0xFFD8A9AB)]),
  HomeCollection(
      title: 'هدايا مميزة',
      query: 'الهدايا',
      image: 'assets/images/product_gift.png',
      labelColors: [Color(0xFFDDF4F0), Color(0xFFD6B798)]),
  HomeCollection(
      title: 'كيك وحلويات',
      query: 'الحلويات',
      image: 'assets/images/product_dessert.png',
      labelColors: [Color(0xFFF4DDAE), Color(0xFFD7AD74)]),
  HomeCollection(
      title: 'عطور وجمال',
      query: 'العطور',
      image: 'assets/images/category_beauty.png',
      labelColors: [Color(0xFFDDF4F0), Color(0xFFDFAE98)]),
  HomeCollection(
      title: 'بالون وتزيين',
      query: 'بالون',
      image: 'assets/images/category_balloons.png',
      labelColors: [Color(0xFFF7E5CF), Color(0xFFDEB898)]),
  HomeCollection(
      title: 'ديكور المنزل',
      query: 'ديكور',
      image: 'assets/images/category_decor.png',
      labelColors: [Color(0xFFDDF4F0), Color(0xFFCAB698)]),
  HomeCollection(
      title: 'ساعات وإكسسوارات',
      query: 'ساعات',
      image: 'assets/images/category_watch.png',
      labelColors: [Color(0xFFDDF4F0), Color(0xFFBEB3A1)]),
  HomeCollection(
      title: 'ورد أحمر',
      query: 'حمراء',
      image: 'assets/images/product_red_roses.png',
      labelColors: [Color(0xFFDDF4F0), Color(0xFFD596A0)]),
];
const homeOccasions = [
  HomeCollection(
      title: 'لمن تحب',
      query: 'حمراء',
      image: 'assets/images/product_red_roses.png',
      labelColors: [Color(0xFFDDF4F0), Color(0xFFD596A0)]),
  HomeCollection(
      title: 'عيد ميلاد',
      query: 'الحلويات',
      image: 'assets/images/product_dessert.png',
      labelColors: [Color(0xFFF4DDAE), Color(0xFFD7AD74)]),
  HomeCollection(
      title: 'هدية للأم',
      query: 'الزهور',
      image: 'assets/images/product_bouquet.png',
      labelColors: [Color(0xFFDDF4F0), Color(0xFFD8A9AB)]),
  HomeCollection(
      title: 'للأصدقاء',
      query: 'الهدايا',
      image: 'assets/images/product_gift.png',
      labelColors: [Color(0xFFDDF4F0), Color(0xFFD6B798)]),
  HomeCollection(
      title: 'لمسة أناقة',
      query: 'العطور',
      image: 'assets/images/category_beauty.png',
      labelColors: [Color(0xFFDDF4F0), Color(0xFFDFAE98)]),
];
