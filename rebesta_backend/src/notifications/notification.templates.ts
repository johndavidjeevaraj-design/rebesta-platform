export const NotificationTemplates = {

  orderAccepted: (restaurant: string) => ({
    title: '🍽️ Order Accepted',
    message: `${restaurant} has accepted your order.`,
    type: 'order',
  }),

  preparing: (restaurant: string) => ({
    title: '👨‍🍳 Preparing Your Food',
    message: `${restaurant} has started preparing your food.`,
    type: 'order',
  }),

  ready: (restaurant: string) => ({
    title: '📦 Order Ready',
    message: `${restaurant} has packed your order.`,
    type: 'order',
  }),

  pickedUp: (driver: string) => ({
    title: '🛵 Order Picked Up',
    message: `${driver} is on the way with your order.`,
    type: 'delivery',
  }),

  delivered: () => ({
    title: '✅ Delivered',
    message: 'Enjoy your meal! Thanks for choosing ReBesta.',
    type: 'delivery',
  }),

};