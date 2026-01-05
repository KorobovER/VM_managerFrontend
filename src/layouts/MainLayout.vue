
<template>
  <q-layout view="lHh Lpr lFf" class="hiveon-bg">
    <q-header elevated class="hiveon-header">
      <q-toolbar>
        <q-toolbar-title>
          <span class="hiveon-logo">VM Manager</span>
        </q-toolbar-title>
      </q-toolbar>
    </q-header>
    <q-page-container>
      <router-view />
    </q-page-container>
  </q-layout>
</template>

<script>
export default {
  name: "MainLayout"
}
</script>

<style scoped>
.hiveon-bg {
  background: var(--hiveon-bg) !important;
  min-height: 100vh;
}
.hiveon-header {
  background: var(--hiveon-card) !important;
  color: var(--hiveon-cyan) !important;
  border-bottom: 1px solid #20262f;
}
.hiveon-logo {
  font-weight: 800;
  font-size: 1.25rem;
  color: var(--hiveon-cyan);
  letter-spacing: 0.03em;
}
</style>
