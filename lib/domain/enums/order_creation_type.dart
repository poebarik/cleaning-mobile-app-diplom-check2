enum OrderCreationType {
  companyCleaners,    // Выбор из клинеров компании
  browseCleaners,     // Просмотр всех клинеров с отзывами
  marketplace,        // Объявление для откликов
}

extension OrderCreationTypeExtension on OrderCreationType {
  String get title {
    switch (this) {
      case OrderCreationType.companyCleaners:
        return 'Клинеры компании';
      case OrderCreationType.browseCleaners:
        return 'Выбрать из списка';
      case OrderCreationType.marketplace:
        return 'Опубликовать объявление';
    }
  }

  String get icon {
    switch (this) {
      case OrderCreationType.companyCleaners:
        return '🏢';
      case OrderCreationType.browseCleaners:
        return '👥';
      case OrderCreationType.marketplace:
        return '📢';
    }
  }

  String get description {
    switch (this) {
      case OrderCreationType.companyCleaners:
        return 'Компания сама назначит клинера';
      case OrderCreationType.browseCleaners:
        return 'Выберите клинера из списка с отзывами';
      case OrderCreationType.marketplace:
        return 'Клинеры сами откликнутся на заказ';
    }
  }
}