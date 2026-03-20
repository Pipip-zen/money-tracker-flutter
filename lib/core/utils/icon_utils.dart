import 'package:flutter/material.dart';

class IconUtils {
  static IconData getIcon(int codePoint) {
    // Map of common icons to their constant equivalents
    // This allows icon tree shaking to work because the constants are explicitly referenced.
    
    // Food & Daily
    if (codePoint == Icons.restaurant.codePoint) return Icons.restaurant;
    if (codePoint == Icons.local_cafe.codePoint) return Icons.local_cafe;
    if (codePoint == Icons.local_grocery_store.codePoint) return Icons.local_grocery_store;
    if (codePoint == Icons.shopping_bag.codePoint) return Icons.shopping_bag;
    if (codePoint == Icons.shopping_cart.codePoint) return Icons.shopping_cart;

    // Transport
    if (codePoint == Icons.directions_car.codePoint) return Icons.directions_car;
    if (codePoint == Icons.directions_bus.codePoint) return Icons.directions_bus;
    if (codePoint == Icons.local_gas_station.codePoint) return Icons.local_gas_station;
    if (codePoint == Icons.flight.codePoint) return Icons.flight;
    if (codePoint == Icons.train.codePoint) return Icons.train;
    if (codePoint == Icons.motorcycle.codePoint) return Icons.motorcycle;

    // Finance & Income
    if (codePoint == Icons.account_balance_wallet.codePoint) return Icons.account_balance_wallet;
    if (codePoint == Icons.savings.codePoint) return Icons.savings;
    if (codePoint == Icons.trending_up.codePoint) return Icons.trending_up;
    if (codePoint == Icons.attach_money.codePoint) return Icons.attach_money;
    if (codePoint == Icons.credit_card.codePoint) return Icons.credit_card;
    if (codePoint == Icons.receipt_long.codePoint) return Icons.receipt_long;
    if (codePoint == Icons.payment.codePoint) return Icons.payment;
    if (codePoint == Icons.account_balance.codePoint) return Icons.account_balance;
    if (codePoint == Icons.currency_exchange.codePoint) return Icons.currency_exchange;
    if (codePoint == Icons.monetization_on.codePoint) return Icons.monetization_on;
    if (codePoint == Icons.business_center.codePoint) return Icons.business_center;
    if (codePoint == Icons.work.codePoint) return Icons.work;
    if (codePoint == Icons.laptop.codePoint) return Icons.laptop;

    // Lifestyle
    if (codePoint == Icons.sports_esports.codePoint) return Icons.sports_esports;
    if (codePoint == Icons.movie.codePoint) return Icons.movie;
    if (codePoint == Icons.music_note.codePoint) return Icons.music_note;
    if (codePoint == Icons.fitness_center.codePoint) return Icons.fitness_center;
    if (codePoint == Icons.local_hospital.codePoint) return Icons.local_hospital;
    if (codePoint == Icons.school.codePoint) return Icons.school;
    if (codePoint == Icons.book.codePoint) return Icons.book;
    if (codePoint == Icons.home.codePoint) return Icons.home;
    if (codePoint == Icons.electrical_services.codePoint) return Icons.electrical_services;
    if (codePoint == Icons.wifi.codePoint) return Icons.wifi;
    if (codePoint == Icons.phone_android.codePoint) return Icons.phone_android;
    if (codePoint == Icons.child_care.codePoint) return Icons.child_care;
    if (codePoint == Icons.pets.codePoint) return Icons.pets;
    if (codePoint == Icons.celebration.codePoint) return Icons.celebration;
    if (codePoint == Icons.card_giftcard.codePoint) return Icons.card_giftcard;
    if (codePoint == Icons.volunteer_activism.codePoint) return Icons.volunteer_activism;
    if (codePoint == Icons.more_horiz.codePoint) return Icons.more_horiz;
    
    // Fallback to a constant icon to satisfy the tree shaker
    return Icons.help_outline;
  }
}
