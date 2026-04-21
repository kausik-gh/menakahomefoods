/// Menu and cart prices are derived only from [isVeg], never from database.
double dishPrice(bool isVeg) => isVeg ? 120.0 : 220.0;

/// Alias matching app spec (`getPrice`) — always use this for display totals.
double getPrice(bool isVeg) => dishPrice(isVeg);
