# VetNow

**A full-stack booking and management platform for veterinary stations** — clients find a nearby clinic on a map, book an appointment in an available time slot, and manage their pets' visits; clinic staff manage their team, availability, and appointments from a dashboard.

Built with **Angular 17** and **ASP.NET Core** on **SQL Server**, with role-based access control, custom token authentication, and background job scheduling.

![Angular](https://img.shields.io/badge/Angular-17-DD0031?logo=angular&logoColor=white)
![.NET](https://img.shields.io/badge/.NET-ASP.NET%20Core-512BD4?logo=dotnet&logoColor=white)
![EF Core](https://img.shields.io/badge/EF%20Core-7-512BD4)
![SQL Server](https://img.shields.io/badge/SQL%20Server-CC2927?logo=microsoftsqlserver&logoColor=white)
![TypeScript](https://img.shields.io/badge/TypeScript-5.2-3178C6?logo=typescript&logoColor=white)
![Tailwind](https://img.shields.io/badge/Tailwind-3.4-06B6D4?logo=tailwindcss&logoColor=white)

---

## What it does

**For pet owners**
- Search for veterinary stations and view them on an interactive map
- Browse a clinic's staff and services before booking
- Book, reschedule, and cancel appointments against real availability
- Register with email verification and manage a profile with pet records

**For clinic staff**
- Manage the clinic team across distinct roles — veterinarians, nurses, and groomers
- Define working hours and availability windows that drive bookable slots
- View appointments and clinic statistics from a dashboard
- Generate PDF documents from appointment and clinic data

---

## Architecture

```
┌─────────────────────────┐        HTTPS / JSON        ┌──────────────────────────┐
│   Angular 17 SPA        │  ───────────────────────▶ │   ASP.NET Core Web API   │
│                         │                            │                          │
│  • Angular Material     │  ◀───────────────────────  │  • Endpoint-per-feature  │
│  • Tailwind CSS         │      token auth header     │  • Policy authorization  │
│  • Leaflet / Google Maps│                            │  • FluentValidation      │
│  • Route guards         │                            │  • Background services   │
└─────────────────────────┘                            └────────────┬─────────────┘
                                                                    │ EF Core 7
                                                       ┌────────────▼─────────────┐
                                                       │       SQL Server         │
                                                       │  Table-Per-Type domain   │
                                                       └──────────────────────────┘
```

### Engineering decisions worth a look

<details>
<summary><b>Table-Per-Type inheritance for the staff domain</b></summary>

<br>

A clinic has several kinds of people who share identity data but differ in behaviour and permissions. Rather than one wide table with nullable columns, the domain models real inheritance:

```
Person
└── Employee
    ├── Vet
    ├── Nurse
    ├── Barber      (grooming staff)
    └── MainVet     (clinic owner / administrator)
```

EF Core is configured for **Table-Per-Type** mapping, so each type gets its own table and shares a primary key. The trade-off is deliberate: TPT costs a join on read but keeps the schema normalised and makes role-specific columns non-nullable, which is what the authorization policies depend on.

</details>

<details>
<summary><b>Custom token authentication scheme</b></summary>

<br>

Authentication is implemented as a custom `AuthenticationHandler` registered as its own scheme, rather than dropping in an off-the-shelf JWT package. Tokens are persisted with issue time and originating IP, and a hosted `TokenCleanupService` expires stale tokens in the background.

Passwords are hashed with **BCrypt**. Google sign-in is supported via `Google.Apis.Auth` on the API side and `angular-oauth2-oidc` on the client.

</details>

<details>
<summary><b>Policy-based authorization</b></summary>

<br>

Authorization is not a set of scattered role string checks. Policies are registered centrally through an extension method (`AddVetStationPolicies`), so an endpoint declares *what it requires* and the policy decides how that is satisfied — including whether the caller belongs to the clinic whose data they are touching.

</details>

<details>
<summary><b>Background scheduling for appointment slots</b></summary>

<br>

Bookable time slots are generated from each clinic's declared availability by a `TimeSlotGeneratorService`, driven by a hosted `AppointmentGeneratorService` that runs on startup and on a daily interval.

This is documented in the code as a development-environment approach; a production deployment would move it to a dedicated scheduler such as Hangfire, Quartz.NET, or an Azure Timer Trigger.

</details>

<details>
<summary><b>Cross-cutting concerns as middleware</b></summary>

<br>

A custom `ExceptionHandlingMiddleware` sits in front of the pipeline so controllers and endpoints return domain results and never hand-roll error responses. Request validation is handled declaratively with **FluentValidation**, and the API is documented with **Swagger/OpenAPI**, including the custom auth header as a security definition so the spec is actually usable from the Swagger UI.

</details>

---

## Tech stack

| Layer | Technology |
| --- | --- |
| **Frontend** | Angular 17, TypeScript 5.2, RxJS |
| **UI** | Angular Material + CDK, Tailwind CSS, Bootstrap, FontAwesome, Swiper |
| **Maps** | Leaflet, Google Maps for Angular |
| **Auth (client)** | `angular-oauth2-oidc`, route guards |
| **Backend** | ASP.NET Core Web API, C# |
| **Data** | Entity Framework Core 7, SQL Server, TPT inheritance, explicit indexing |
| **Security** | Custom token authentication scheme, BCrypt hashing, policy-based authorization |
| **Validation** | FluentValidation |
| **Docs** | Swagger / Swashbuckle |
| **Reporting** | QuestPDF |
| **Email** | SMTP email service with verification flow |
| **Testing** | xUnit-style test project (backend), Karma + Jasmine (frontend) |
| **Tooling** | Docker, custom Webpack build, Azure DevOps |

---

## Getting started

### Prerequisites

- [.NET SDK](https://dotnet.microsoft.com/download)
- [Node.js](https://nodejs.org/) 18+ and npm
- SQL Server (LocalDB, Express, or a container)

### 1. Clone

```bash
git clone https://github.com/Ibro02/vetnow-angular-dotnet.git
cd vetnow-angular-dotnet
```

### 2. Configure the API

Secrets are **not** stored in the repository. Use .NET user secrets or environment variables:

```bash
cd VetStat
dotnet user-secrets set "ConnectionStrings:DefaultConnection" "Server=localhost;Database=VetNow;Trusted_Connection=True;TrustServerCertificate=True"
dotnet user-secrets set "AppSettings:Token" "<a long random signing key>"
dotnet user-secrets set "EmailServer:Host" "smtp.example.com"
dotnet user-secrets set "EmailServer:Port" "587"
dotnet user-secrets set "EmailServer:From" "<sender address>"
dotnet user-secrets set "EmailServer:Password" "<app password>"
```

Copy `appsettings.Example.json` to `appsettings.Development.json` if you prefer file-based configuration locally.

### 3. Create the database

```bash
dotnet ef database update
```

The API seeds demo data automatically on first run in the Development environment.

### 4. Run the API

```bash
dotnet run
```

Swagger UI is then available at `https://localhost:<port>/swagger`.

### 5. Run the frontend

```bash
cd ../frontend
npm install
npm start
```

The app runs at `http://localhost:4200`.

> [!NOTE]
> The frontend reads its API base URL and map keys from a `.env` file via `dotenv-webpack`. Copy `.env.example` to `.env` and fill in your values before starting.

---

## Project structure

```
vetnow-angular-dotnet/
├── VetStat/                    # ASP.NET Core Web API
│   ├── Controllers/            # MVC controllers
│   ├── Endpoints/              # Feature-scoped endpoint classes, one per operation
│   ├── Models/                 # Domain entities (Person → Employee → Vet/Nurse/…)
│   ├── Data/                   # EF Core DbContext, TPT mapping, indexes, seeding
│   ├── Helpers/
│   │   ├── Auth/               # Custom authentication scheme and handler
│   │   ├── Services/           # Email, appointments, time slots, token cleanup
│   │   ├── Validators/         # FluentValidation rules
│   │   └── Middleware/         # Global exception handling
│   ├── Extensions/             # Authorization policy registration, seeding extensions
│   └── Program.cs              # Composition root — DI, auth, CORS, pipeline
│
├── VetStat.Tests/              # Backend test project
│
├── frontend/                   # Angular 17 SPA
│   └── src/app/
│       ├── pages/              # Routed feature pages
│       ├── components/         # Reusable UI components
│       ├── services/           # Typed HTTP clients
│       └── guards/             # Route protection
│
└── documents/                  # Project documentation and diagrams
```

---

## Testing

```bash
# Backend
dotnet test

# Frontend
cd frontend && npm test
```

---

## Roadmap

- Replace the interval-based slot generator with a dedicated scheduler (Hangfire / Quartz.NET)
- Tighten the development CORS policy to an explicit origin allowlist for production
- Expand backend test coverage across the appointment and availability services
- Containerise the full stack with Docker Compose for one-command local setup

---

## About this project

VetNow was built as a full-stack academic project and developed like a real product — tracked in Azure DevOps with a written ticket backlog, code review feedback from a mentor, and 200+ commits of iteration.

**My contribution:** *(fill this in — be specific about which parts you owned; interviewers ask.)*

Co-authored with [Tarik Ganić](https://github.com/tarikganic).

---

## License

Released under the MIT License. See [`LICENSE`](LICENSE) for details.
