# VetStation — Remaining Tickets

---

[BUG] MainVetController.Edit does not update any properties
The Edit method in MainVetController only copies the incoming Id onto the existing entity and calls SaveChanges() — no actual fields (FirstName, LastName, Email, etc.) are updated. The endpoint exists but is completely non-functional. Fix: Map all editable properties from the incoming `mainvet` object onto `_mainvet` before calling SaveChanges(). Files: VetStat/Controllers/MainVetController.cs (Edit method, lines ~74-87)

---

[BUG] Sync endpoints named HandleAsync without async keyword
27 endpoints declare `public ActionResult HandleAsync(...)` without the `async` keyword or any `await` usage. The "Async" suffix is misleading and generates IDE warnings. Fix: Either make these methods truly async with `await` on DB calls, or rename them to `Handle()` to match their synchronous nature. Files: AppointmentCancelEndpoint.cs, AppointmentGetByCustomerIdEndpoint.cs, AppointmentRescheduleEndpoint.cs, AvailabilityAddEndpoint.cs, AvailabilityDeleteEndpoint.cs, AvailabilityEditEndpoint.cs, DashboardGetStatsEndpoint.cs, EmployeeDeleteEndpoint.cs, EmployeeEditEndpoint.cs, EmployeeGetAllEndpoint.cs, EmployeeGetByVetStationIdEndpoint.cs, EmployeeGetBarbersByVetStationId.cs, EmployeeGetNursesByVetStationId.cs, EmployeeGetVetsByVetStationId.cs, PersonGetAllEndpoint.cs, and 12 others

---

[BUG] Registration redirects to root without auth token
After successful registration, `register.component.ts` calls `this.router.navigate([''])` and shows a toaster saying "Please log in with your new account." However, the user is sent to the root route which may be guarded. Fix: Redirect to the login page explicitly (e.g., `this.router.navigate(['login'])`) so the flow is clear and no guard blocks the user. Files: frontend/src/app/pages/register/register.component.ts

---

[BUG] Animal.Name declared as non-nullable string with [Required] — contradictory intent
Animal.Name is `[Required] public string Name { get; set; }` which is redundant (EF Core already treats non-nullable strings as required). The mentor flagged a contradiction with `string?` (nullable). If Name should be optional, make it `string?` and remove `[Required]`. If it must be required, the current form is technically fine but should be explicitly documented. Fix: Clarify intent — either make `Name` nullable (`string?`) without `[Required]`, or keep it non-nullable and add a comment explaining the design choice. Files: VetStat/Models/Animal.cs

---

[BUG] AvailabilityAddEndpoint does not check for existing availability
When adding a new availability, the endpoint does not check whether an availability record already exists for that employee. This can lead to duplicate availability entries and conflicting time slot generation. Fix: Before inserting, check `_db.Availability.Any(a => a.EmployeeId == availability.EmployeeId)` and return a conflict response if one exists. Files: VetStat/Endpoints/AvailabilityEndpoints/AvailabilityAddEndpoint.cs

---

[BUG] TimeSlotGetEndpoint uses unsafe date parsing without validation
Date parsing uses `new DateTime(int.Parse(date.Split("-")[0]), int.Parse(date.Split("-")[1]), int.Parse(date.Split("-")[2]))` with no try/catch or format validation. Any malformed input (e.g., "abc-def-ghi" or empty string) causes an unhandled FormatException resulting in HTTP 500. Fix: Replace with `DateTime.TryParseExact(date, "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out var _date)` and return BadRequest if parsing fails. Files: VetStat/Endpoints/TimeSlotEndpoints/TimeSlotGetEndpoint.cs (lines 23-24)

---

[BUG] Six controllers still return raw EF entities without DTOs
CategoryController, FAQController, InventoryController, ProductController, SpeciesController, and SubCategoryController return database entities directly in their responses. This leaks internal fields and couples the frontend to the database schema. Fix: Create response DTOs for each entity (CategoryResponse, FAQResponse, etc.) and map entities through them before returning. Files: VetStat/Controllers/CategoryController.cs, FAQController.cs, InventoryController.cs, ProductController.cs, SpeciesController.cs, SubCategoryController.cs

---

[BUG] RoleController.Delete has redundant SaveChanges() after ExecuteDelete()
`ExecuteDelete()` executes immediately against the database without the change tracker. The subsequent `_db.SaveChanges()` call is redundant and represents a double-commit anti-pattern. Fix: Remove the `_db.SaveChanges()` call after `ExecuteDelete()`. Files: VetStat/Controllers/RoleController.cs (line 87)

---

[BUG] Leftover enviroment.ts (typo) file still exists in frontend
Both `frontend/src/enviroment.ts` (typo) and `frontend/src/environment.ts` (correct) exist. No component imports from the typo version, making it dead code. Additionally, DB column names still retain old typos (IpAdress, LoggTime) via HasColumnName mappings — these are cosmetic but noted. Fix: Delete `frontend/src/enviroment.ts`. Optionally create a migration to rename DB columns if desired. Files: frontend/src/enviroment.ts (delete), VetStat/Data/DataContext.cs (column name mappings — optional)

---

[BUG] AdminController.Edit saves password without hashing
In AdminController.Edit, the password is updated with `_admin.Password = admin.Password` without running it through PasswordHasher.Hash(). This means admin password changes are stored in plain text while all other flows correctly use BCrypt. Fix: Add `_admin.Password = PasswordHasher.Hash(admin.Password)` when the password field is being updated. Files: VetStat/Controllers/AdminController.cs (line ~78-79)

---

[BUG] Person.Password property lacks [JsonIgnore] attribute
While the DTO pattern prevents password serialization in most endpoints, the Person model itself does not have `[JsonIgnore]` on the Password property. If any endpoint accidentally returns a raw Person entity (or if serialization happens in logging/caching), the password hash would be exposed. Fix: Add `[JsonIgnore]` attribute to `public string Password { get; set; }` on the Person model as defense-in-depth. Files: VetStat/Models/Person.cs (line 34)

---

[BUG] ProfileGetUserInfoEndpoint catch block leaks exception message to client
The catch block in ProfileGetUserInfoEndpoint returns `BadRequest(e.Message)` which bypasses the global ExceptionHandlingMiddleware (since the exception is caught locally). This can expose internal details like SQL errors or stack trace information. Fix: Replace `return BadRequest(e.Message)` with a generic error message like `return BadRequest("Could not retrieve user profile. Please try again.")`. Files: VetStat/Endpoints/ProfileEndpoints/ProfileGetUserInfoEndpoint.cs (line 41)

---
