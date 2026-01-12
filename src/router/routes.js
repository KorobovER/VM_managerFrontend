const routes = [
  {
    path: '/login',
    component: () => import('pages/LoginPage.vue'),
  },
  {
    path: '/',
    component: () => import('layouts/MainLayout.vue'),
    meta: { requiresAuth: true },
    children: [
      {
        path: '',
        component: () => import('pages/IndexPage.vue'),
        meta: { requiresAuth: true },
      },
      {
        path: 'servers',
        component: () => import('pages/ServersPage.vue'),
        meta: { requiresAuth: true, requiresAdmin: true },
      },
      {
        path: 'register',
        component: () => import('pages/RegisterPage.vue'),
        meta: { requiresAuth: true, requiresAdmin: true },
      },
    ],
  },

  // Always leave this as last one,
  // but you can also remove it
  {
    path: '/:catchAll(.*)*',
    component: () => import('pages/ErrorNotFound.vue'),
  },
]

export default routes
