# SIMK API

PHP REST API backend for **Sistem Informasi Manajemen Katering (SIMK)**.

## Requirements

- PHP 8.1+
- MySQL 8.0+
- Apache with `mod_rewrite` (or PHP built-in server for development)

## Quick Setup

1. Copy environment file:
   ```bash
   cp .env.example .env
   ```

2. Edit `.env` with your MySQL credentials.

3. Run database setup:
   ```bash
   php setup.php
   ```

4. Start the API (development):
   ```bash
   cd public
   php -S localhost:8080
   ```

   Base URL: `http://localhost:8080`

## Apache (Production)

Point document root to `api/public` or place the `api` folder under your web root as `/api`.

Example virtual host:
```
DocumentRoot "C:/xampp/htdocs/simk-api/public"
```

API will be available at `http://localhost/api` when using the root `.htaccess` rewrite.

## Demo Accounts

| Email | Password | Role |
|-------|----------|------|
| admin@simk.id | admin123 | Admin |
| kasir@simk.id | kasir123 | Kasir |
| produksi@simk.id | produksi123 | Staff Produksi |

## Connect Flutter App

```bash
cd simk
flutter run --dart-define=USE_MOCK_DATA=false --dart-define=API_BASE_URL=http://localhost:8080
```

For Android emulator use `http://10.0.2.2:8080`.

## Endpoints

| Method | Path | Auth |
|--------|------|------|
| POST | `/auth/login` | No |
| GET | `/auth/me` | Yes |
| GET | `/dashboard` | Yes |
| GET | `/users` | Yes (admin) |
| GET | `/customers` | Yes |
| GET | `/orders` | Yes |
| GET | `/recipe-categories` | Yes |
| GET | `/recipes` | Yes |
| GET | `/ingredients` | Yes |
| GET | `/production` | Yes |
| GET | `/payments` | Yes |
| GET | `/reports/{type}?period=` | Yes (admin) |

Report types: `sales`, `orders`, `inventory`, `ingredients`, `revenue`.
