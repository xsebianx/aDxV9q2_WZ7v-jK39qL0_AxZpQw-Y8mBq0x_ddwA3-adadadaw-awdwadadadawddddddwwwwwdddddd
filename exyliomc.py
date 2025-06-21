import discord
from discord import app_commands
from discord.ext import commands
import asyncio
import datetime
from dotenv import load_dotenv
import os
import webserver
import random
import io
import html
import json
import os.path
import shutil
import glob
import sqlite3
import zlib
import tracemalloc

# Iniciar monitoreo de memoria
tracemalloc.start()

# Cargar variables de entorno
load_dotenv()
os.environ["DISCORD_INTERNAL_NO_VOICE"] = "true"
os.environ["PYTHONUNBUFFERED"] = "1"

# Configuración de intents optimizada
intents = discord.Intents.default()
intents.messages = True
intents.message_content = True
intents.members = True
intents.reactions = False
intents.typing = False
intents.presences = False

bot = commands.Bot(
    command_prefix='!',
    intents=intents,
    help_command=None
)

# Configuración
CATEGORIA_TICKETS = "🎫 TICKETS"
ROLES_STAFF = []
ESTADOS_TICKET = ["🟡 Pendiente", "🟢 Resuelto", "🔴 Necesita respuesta", "🔒 Archivado"]

# Archivos de almacenamiento
BASE_PATH = os.path.join(os.getcwd(), "data")
os.makedirs(BASE_PATH, exist_ok=True)

DB_FILE = os.path.join(BASE_PATH, "tickets.db")
STAFF_ROLES_FILE = os.path.join(BASE_PATH, "staff_roles.json")
CONFIG_FILE = os.path.join(BASE_PATH, "config.json")
ATTACHMENTS_BASE = os.path.join(BASE_PATH, "ticket_attachments")
os.makedirs(ATTACHMENTS_BASE, exist_ok=True)

# Variable global para el canal de logs
CANAL_LOGS_OBJ = None
CANAL_ARCHIVOS_OBJ = None

# Colores temáticos
MINECRAFT_GREEN = 0x55FF55
MINECRAFT_BLUE = 0x55CDFF
MINECRAFT_RED = 0xFF5555
MINECRAFT_GOLD = 0xFFAA00
MINECRAFT_PURPLE = 0xAA00FF

# Emojis
MINECRAFT_EMOJIS = ["⛏️", "🌲", "🪓", "🔨", "🌑", "🔥", "💎", "🌾", "🍖", "🏹", "🛡️", "🧪", "🧭", "🗺️", "🧱", "🪵"]

# Inicializar base de datos SQLite
def init_db():
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS tickets (
            canal_id TEXT PRIMARY KEY,
            usuario_id TEXT,
            estado TEXT,
            fecha_creacion TEXT,
            fecha_archivado TEXT,
            guild_id TEXT
        )
    ''')
    conn.commit()
    conn.close()

init_db()

# Cargar datos desde archivos JSON
def cargar_datos():
    global ROLES_STAFF
    
    # Inicializar datos
    config_data = {}
    staff_roles = []
    
    # Cargar roles de staff
    if os.path.exists(STAFF_ROLES_FILE):
        try:
            with open(STAFF_ROLES_FILE, 'r') as f:
                staff_roles = json.load(f)
        except:
            pass
    
    # Cargar configuración
    if os.path.exists(CONFIG_FILE):
        try:
            with open(CONFIG_FILE, 'r') as f:
                config_data = json.load(f)
                if not isinstance(config_data, dict):
                    config_data = {}
        except:
            config_data = {}
    else:
        config_data = {}
    
    ROLES_STAFF = staff_roles
    return config_data

# Funciones de base de datos
def get_ticket(canal_id):
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM tickets WHERE canal_id = ?", (str(canal_id),))
    result = cursor.fetchone()
    conn.close()
    
    if result:
        return {
            "canal_id": result[0],
            "usuario_id": result[1],
            "estado": result[2],
            "fecha_creacion": result[3],
            "fecha_archivado": result[4],
            "guild_id": result[5]
        }
    return None

def save_ticket(ticket_data):
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    cursor.execute('''
        INSERT OR REPLACE INTO tickets 
        (canal_id, usuario_id, estado, fecha_creacion, fecha_archivado, guild_id)
        VALUES (?, ?, ?, ?, ?, ?)
    ''', (
        str(ticket_data["canal_id"]),
        str(ticket_data["usuario_id"]),
        ticket_data["estado"],
        ticket_data["fecha_creacion"],
        ticket_data["fecha_archivado"],
        str(ticket_data["guild_id"])
    ))
    conn.commit()
    conn.close()

def delete_ticket(canal_id):
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    cursor.execute("DELETE FROM tickets WHERE canal_id = ?", (str(canal_id),))
    conn.commit()
    conn.close()

def get_active_tickets(guild_id):
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM tickets WHERE guild_id = ? AND fecha_archivado IS NULL", (str(guild_id),))
    results = cursor.fetchall()
    conn.close()
    
    tickets = []
    for result in results:
        tickets.append({
            "canal_id": result[0],
            "usuario_id": result[1],
            "estado": result[2],
            "fecha_creacion": result[3],
            "fecha_archivado": result[4],
            "guild_id": result[5]
        })
    return tickets

def get_all_tickets():
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM tickets")
    results = cursor.fetchall()
    conn.close()
    
    tickets = []
    for result in results:
        tickets.append({
            "canal_id": result[0],
            "usuario_id": result[1],
            "estado": result[2],
            "fecha_creacion": result[3],
            "fecha_archivado": result[4],
            "guild_id": result[5]
        })
    return tickets

# Guardar roles de staff
def guardar_staff_roles():
    with open(STAFF_ROLES_FILE, 'w') as f:
        json.dump(ROLES_STAFF, f, indent=4)

# Limpiar archivos antiguos
def limpiar_adjuntos_antiguos():
    ahora = datetime.datetime.now()
    for carpeta_ticket in glob.glob(os.path.join(ATTACHMENTS_BASE, "*")):
        if os.path.isdir(carpeta_ticket):
            stats = os.stat(carpeta_ticket)
            fecha_modificacion = datetime.datetime.fromtimestamp(stats.st_mtime)
            if (ahora - fecha_modificacion).days > 20:
                try:
                    shutil.rmtree(carpeta_ticket)
                    print(f"♻️ Limpiada carpeta de adjuntos antigua: {carpeta_ticket}")
                except Exception as e:
                    print(f"❌ Error al eliminar carpeta {carpeta_ticket}: {e}")

# Inicializar almacenamiento
config = cargar_datos()

# Definición de todas las clases con __slots__
class TicketView(discord.ui.View):
    def __init__(self):
        # Añade timeout=None en el super().__init__()
        super().__init__(timeout=None)
        
    @discord.ui.button(label="Archivar Ticket", style=discord.ButtonStyle.red, custom_id="archivar_ticket", emoji="🔒", row=0)
    async def archivar_ticket(self, interaction: discord.Interaction, button: discord.ui.Button):
        await archivar_ticket_handler(interaction)
        
    @discord.ui.button(label="Generar Transcript", style=discord.ButtonStyle.blurple, custom_id="transcript_ticket", emoji="📜", row=0)
    async def transcript_ticket(self, interaction: discord.Interaction, button: discord.ui.Button):
        await transcript_handler(interaction)

class EstadoSelect(discord.ui.Select):
    def __init__(self):
        options = [
            discord.SelectOption(label="🟡 Pendiente", description="El ticket está pendiente de revisión"),
            discord.SelectOption(label="🟢 Resuelto", description="El problema ha sido resuelto"),
            discord.SelectOption(label="🔴 Necesita respuesta", description="Esperando respuesta del usuario")
        ]
        super().__init__(
            placeholder="Cambiar estado del ticket...",
            options=options,
            custom_id="estado_select"
        )
        
        # Solución: almacenar explícitamente el custom_id
        self.custom_id = "estado_select"
    
    async def callback(self, interaction: discord.Interaction):
        if not any(role.name in ROLES_STAFF for role in interaction.user.roles):
            await interaction.response.send_message("❌ Solo el staff puede cambiar el estado del ticket.", ephemeral=True)
            return
        
        nuevo_estado = self.values[0]
        
        # Actualizar almacenamiento
        canal_id = str(interaction.channel.id)
        ticket = get_ticket(canal_id)
        if ticket:
            ticket["estado"] = nuevo_estado
            save_ticket(ticket)
        
        # Buscar y actualizar el embed principal
        async for message in interaction.channel.history(limit=10):
            if message.embeds and message.author == bot.user:
                original_embed = message.embeds[0]
                
                for i, field in enumerate(original_embed.fields):
                    if field.name == "📝 Estado":
                        original_embed.set_field_at(i, name="📝 Estado", value=nuevo_estado, inline=True)
                        
                        # Cambiar color según estado
                        if "Resuelto" in nuevo_estado:
                            original_embed.color = MINECRAFT_GREEN
                        elif "Pendiente" in nuevo_estado:
                            original_embed.color = MINECRAFT_BLUE
                        elif "Necesita respuesta" in nuevo_estado:
                            original_embed.color = MINECRAFT_RED
                        
                        break
                
                await message.edit(embed=original_embed)
                break
        
        await interaction.response.send_message(f"✅ Estado actualizado a **{nuevo_estado}**", ephemeral=True)

class EstadoView(discord.ui.View):
    def __init__(self):
        # Añade timeout=None
        super().__init__(timeout=None)
        self.add_item(EstadoSelect())

class PanelTicketView(discord.ui.View):
    def __init__(self):
        # Añade timeout=None
        super().__init__(timeout=None)
        
    @discord.ui.button(label="Crear Ticket", style=discord.ButtonStyle.green, custom_id="crear_ticket_panel", emoji="📩")
    async def crear_ticket_panel(self, interaction: discord.Interaction, button: discord.ui.Button):
        class Payload:
            __slots__ = ('guild_id', 'user_id', 'member')
            
            def __init__(self, guild_id, user_id):
                self.guild_id = guild_id
                self.user_id = user_id
                self.member = interaction.user
        
        payload = Payload(interaction.guild.id, interaction.user.id)
        await interaction.response.defer(ephemeral=True)
        await crear_ticket(payload)
        
        embed = discord.Embed(
            description="✅ **Ticket creado con éxito!**\n\nSe ha creado un canal privado para tu solicitud.",
            color=MINECRAFT_GREEN
        )
        await interaction.followup.send(embed=embed, ephemeral=True)

class ConfirmArchiveView(discord.ui.View):
    def __init__(self):
        # Este tiene timeout=30, está correcto
        super().__init__(timeout=30)
        
    @discord.ui.button(label="Confirmar Archivo", style=discord.ButtonStyle.red, emoji="🔒")
    async def confirm_archive(self, interaction: discord.Interaction, button: discord.ui.Button):
        await archivar_ticket_confirmado(interaction)
        
    @discord.ui.button(label="Cancelar", style=discord.ButtonStyle.green, emoji="✅")
    async def cancel_archive(self, interaction: discord.Interaction, button: discord.ui.Button):
        await interaction.response.edit_message(
            content="✅ **Operación cancelada** - El ticket permanece abierto",
            embed=None,
            view=None
        )

class AfterArchiveView(discord.ui.View):
    def __init__(self):
        # Añade timeout=None
        super().__init__(timeout=None)
        
    @discord.ui.button(label="Reabrir Ticket", style=discord.ButtonStyle.green, custom_id="reabrir_ticket", emoji="🔓")
    async def reabrir_ticket(self, interaction: discord.Interaction, button: discord.ui.Button):
        await reabrir_ticket_handler(interaction)
        
    @discord.ui.button(label="Eliminar Ticket", style=discord.ButtonStyle.red, custom_id="eliminar_ticket", emoji="🗑️")
    async def eliminar_ticket(self, interaction: discord.Interaction, button: discord.ui.Button):
        await eliminar_ticket_handler(interaction)

# Eventos y comandos
@bot.event
async def on_ready():
    global CANAL_LOGS_OBJ, CANAL_ARCHIVOS_OBJ
    
    print(f'✅ Bot conectado como {bot.user.name}')
    print(f'🆔 ID del bot: {bot.user.id}')
    print(f'🕒 Hora de conexión: {datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")}')
    
    # Tomar snapshot de memoria
    snapshot = tracemalloc.take_snapshot()
    top_stats = snapshot.statistics('lineno')
    print("[Top 10 de uso de memoria]")
    for stat in top_stats[:10]:
        print(stat)
    
    # Registrar vistas persistentes
    bot.add_view(TicketView())
    bot.add_view(PanelTicketView())
    bot.add_view(EstadoView())
    bot.add_view(AfterArchiveView())
    
    # Sincronizar comandos
    try:
        synced = await bot.tree.sync()
        print(f"✅ Sincronizados {len(synced)} comandos de barra")
    except Exception as e:
        print(f"❌ Error sincronizando comandos: {e}")
    
    # Limpiar tickets de canales eliminados
    tickets = get_all_tickets()
    for ticket in tickets:
        canal = bot.get_channel(int(ticket["canal_id"]))
        if not canal:
            delete_ticket(ticket["canal_id"])
            print(f"♻️ Eliminado ticket de canal inexistente: {ticket['canal_id']}")
    
    # Establecer estado
    await bot.change_presence(
        activity=discord.Activity(
            type=discord.ActivityType.watching,
            name="Tickets | /ayuda"
        )
    )
    
    # Cargar canal de logs y archivos desde config
    for guild in bot.guilds:
        guild_id = str(guild.id)
        if guild_id in config:
            # Canal de logs
            canal_logs_id = config[guild_id].get("logs")
            if canal_logs_id:
                canal_logs = guild.get_channel(int(canal_logs_id))
                if canal_logs:
                    CANAL_LOGS_OBJ = canal_logs
                    print(f"✅ Canal de logs cargado: {CANAL_LOGS_OBJ.name} en {guild.name}")
                else:
                    print(f"❌ Canal de logs no encontrado (ID: {canal_logs_id}) en {guild.name}")
            
            # Canal de archivos
            canal_archivos_id = config[guild_id].get("archivos")
            if canal_archivos_id:
                canal_archivos = guild.get_channel(int(canal_archivos_id))
                if canal_archivos:
                    CANAL_ARCHIVOS_OBJ = canal_archivos
                    print(f"✅ Canal de archivos cargado: {CANAL_ARCHIVOS_OBJ.name} en {guild.name}")
                else:
                    print(f"❌ Canal de archivos no encontrado (ID: {canal_archivos_id}) en {guild.name}")
    
    # Limpiar archivos antiguos al iniciar
    limpiar_adjuntos_antiguos()
    
    # Programar limpieza periódica cada 24 horas
    bot.loop.create_task(limpieza_periodica())
    
    # Recuperar tickets activos
    for guild in bot.guilds:
        tickets_activos = get_active_tickets(guild.id)
        for ticket in tickets_activos:
            canal = guild.get_channel(int(ticket["canal_id"]))
            if canal:
                # Verificar permisos
                await canal.send("✅ **Ticket recuperado** - Este ticket fue restaurado tras un reinicio del bot")
                
                # Recargar vistas
                view = TicketView()
                estado_view = EstadoView()
                
                try:
                    await canal.send(view=view)
                    await canal.send(view=estado_view)
                except Exception as e:
                    print(f"⚠️ Error cargando vistas en {canal.name}: {e}")

async def limpieza_periodica():
    await bot.wait_until_ready()
    while not bot.is_closed():
        await asyncio.sleep(24 * 3600)  # 24 horas
        limpiar_adjuntos_antiguos()
        
        # Monitoreo de memoria
        snapshot = tracemalloc.take_snapshot()
        top_stats = snapshot.statistics('lineno')
        print("[Memoria - Top 10]")
        for stat in top_stats[:10]:
            print(stat)
        
        print("♻️ Ejecutada limpieza periódica")

# COMANDOS
@bot.tree.command(name="establecer_canal_logs", description="📝 Establece el canal para los registros de tickets")
@app_commands.checks.has_permissions(administrator=True)
async def establecer_canal_logs(interaction: discord.Interaction, canal: discord.TextChannel):
    global CANAL_LOGS_OBJ, config
    
    # Guardar en config
    config = {} if not isinstance(config, dict) else config
    guild_id = str(interaction.guild.id)
    
    if guild_id not in config:
        config[guild_id] = {}
    
    config[guild_id]["logs"] = str(canal.id)
    
    # Guardar en archivo
    with open(CONFIG_FILE, 'w') as f:
        json.dump(config, f, indent=4)
    
    CANAL_LOGS_OBJ = canal
    
    embed = discord.Embed(
        description=f"✅ **Canal de logs establecido en {canal.mention}**",
        color=MINECRAFT_GREEN
    )
    await interaction.response.send_message(embed=embed, ephemeral=True)

@bot.tree.command(name="establecer_canal_archivos", description="📁 Establece el canal para archivos adjuntos")
@app_commands.checks.has_permissions(administrator=True)
async def establecer_canal_archivos(interaction: discord.Interaction, canal: discord.TextChannel):
    global CANAL_ARCHIVOS_OBJ, config
    
    # Guardar en config
    config = {} if not isinstance(config, dict) else config
    guild_id = str(interaction.guild.id)
    
    if guild_id not in config:
        config[guild_id] = {}
    
    config[guild_id]["archivos"] = str(canal.id)
    
    # Guardar en archivo
    with open(CONFIG_FILE, 'w') as f:
        json.dump(config, f, indent=4)
    
    CANAL_ARCHIVOS_OBJ = canal
    
    embed = discord.Embed(
        description=f"✅ **Canal de archivos establecido en {canal.mention}**",
        color=MINECRAFT_GREEN
    )
    await interaction.response.send_message(embed=embed, ephemeral=True)

@bot.tree.command(name="staff_agregar", description="🛡️ Agrega un rol a la lista de staff")
@app_commands.checks.has_permissions(administrator=True)
@app_commands.describe(rol="Rol a agregar como staff")
async def staff_agregar(interaction: discord.Interaction, rol: discord.Role):
    if rol.name not in ROLES_STAFF:
        ROLES_STAFF.append(rol.name)
        guardar_staff_roles()
        
        embed = discord.Embed(
            description=f"✅ **Rol {rol.mention} agregado como staff**",
            color=MINECRAFT_GREEN
        )
        await interaction.response.send_message(embed=embed)
    else:
        embed = discord.Embed(
            description=f"ℹ️ El rol {rol.mention} ya está en la lista de staff",
            color=MINECRAFT_BLUE
        )
        await interaction.response.send_message(embed=embed)

@bot.tree.command(name="staff_remover", description="🛡️ Remueve un rol de la lista de staff")
@app_commands.checks.has_permissions(administrator=True)
@app_commands.describe(rol="Rol a remover del staff")
async def staff_remover(interaction: discord.Interaction, rol: discord.Role):
    if rol.name in ROLES_STAFF:
        ROLES_STAFF.remove(rol.name)
        guardar_staff_roles()
        
        embed = discord.Embed(
            description=f"✅ **Rol {rol.mention} removido del staff**",
            color=MINECRAFT_GREEN
        )
        await interaction.response.send_message(embed=embed)
    else:
        embed = discord.Embed(
            description=f"ℹ️ El rol {rol.mention} no está en la lista de staff",
            color=MINECRAFT_BLUE
        )
        await interaction.response.send_message(embed=embed)

@bot.tree.command(name="configurar", description="⚙️ Configura el panel de tickets")
@app_commands.checks.has_permissions(administrator=True)
@app_commands.describe(imagen_url="URL de la imagen para el panel (opcional)")
async def configurar(interaction: discord.Interaction, imagen_url: str = None):
    minecraft_emoji = random.choice(MINECRAFT_EMOJIS)
    
    embed = discord.Embed(
        title=f"{minecraft_emoji} Soporte de Tickets - ExylioMC {minecraft_emoji}",
        description="¡Haz clic en el botón para crear un nuevo ticket de soporte!",
        color=MINECRAFT_GREEN
    )
    
    embed.add_field(
        name="🔍 ¿Cómo funciona?",
        value="1. Haz clic en 📩 para crear un ticket\n2. Describe tu problema en el canal privado\n3. Nuestro equipo te ayudará pronto",
        inline=False
    )
    
    embed.add_field(
        name="📝 Tipos de soporte",
        value="```• Problemas técnicos\n• Reportar jugadores\n• Consultas sobre el servidor\n• Problemas con compras\n• Sugerencias y feedback```",
        inline=False
    )
    
    embed.add_field(
        name="❗ Normas importantes",
        value="```diff\n+ Sé claro con tu problema\n+ Proporciona capturas si es posible\n- No spamees el sistema de tickets\n- Sé respetuoso con el equipo```",
        inline=False
    )
    
    if imagen_url:
        embed.set_image(url=imagen_url)
    
    embed.set_footer(text="Servidor Minecraft ExylioMC")
    
    view = PanelTicketView()
    await interaction.channel.send(embed=embed, view=view)
    
    confirm_embed = discord.Embed(
        description=f"✅ **Panel de tickets configurado correctamente!**\n\nAhora los jugadores pueden crear tickets con el botón.",
        color=MINECRAFT_GREEN
    )
    await interaction.response.send_message(embed=confirm_embed, ephemeral=True)

@bot.tree.command(name="ticket", description="🎫 Crea un nuevo ticket de soporte")
async def crear_ticket_comando(interaction: discord.Interaction):
    class Payload:
        __slots__ = ('guild_id', 'user_id', 'member')
        
        def __init__(self, guild_id, user_id):
            self.guild_id = guild_id
            self.user_id = user_id
            self.member = interaction.user
    
    payload = Payload(interaction.guild.id, interaction.user.id)
    await interaction.response.defer(ephemeral=True)
    await crear_ticket(payload)
    
    embed = discord.Embed(
        description="✅ **Ticket creado con éxito!**\n\nSe ha creado un canal privado para tu solicitud.",
        color=MINECRAFT_GREEN
    )
    await interaction.followup.send(embed=embed, ephemeral=True)

async def crear_ticket(payload):
    guild = bot.get_guild(payload.guild_id)
    usuario = guild.get_member(payload.user_id)
    
    if not usuario:
        return
    
    # Verificación de tickets existentes usando SQLite
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    cursor.execute("SELECT canal_id FROM tickets WHERE usuario_id = ? AND fecha_archivado IS NULL AND guild_id = ?", 
                  (str(usuario.id), str(guild.id)))
    existing_ticket = cursor.fetchone()
    conn.close()
    
    if existing_ticket:
        canal = guild.get_channel(int(existing_ticket[0]))
        if canal:
            try:
                embed = discord.Embed(
                    title="⚠ Ya tienes un ticket abierto",
                    description="Solo puedes tener un ticket activo a la vez.",
                    color=MINECRAFT_GOLD
                )
                embed.add_field(
                    name="Puedes encontrarlo en",
                    value=f"{canal.mention}",
                    inline=False
                )
                await usuario.send(embed=embed)
            except:
                pass
            return
    
    categoria = discord.utils.get(guild.categories, name=CATEGORIA_TICKETS)
    if not categoria:
        categoria = await guild.create_category(CATEGORIA_TICKETS)
    
    nombre_usuario = usuario.display_name[:25]
    
    # Crear canal
    overwrites = {
        guild.default_role: discord.PermissionOverwrite(read_messages=False),
        usuario: discord.PermissionOverwrite(read_messages=True, send_messages=True),
        guild.me: discord.PermissionOverwrite(read_messages=True, send_messages=True)
    }
    
    for role_name in ROLES_STAFF:
        role = discord.utils.get(guild.roles, name=role_name)
        if role:
            overwrites[role] = discord.PermissionOverwrite(read_messages=True, send_messages=True)
    
    try:
        minecraft_emoji = random.choice(MINECRAFT_EMOJIS)
        canal_ticket = await categoria.create_text_channel(
            name=f"{minecraft_emoji}-ticket-{nombre_usuario}",
            overwrites=overwrites
        )
    except Exception as e:
        print(f"❌ Error al crear canal de ticket: {e}")
        return
    
    try:
        # Embed principal con campo de estado
        embed = discord.Embed(
            title=f"🎮 Ticket de {usuario.display_name}",
            description=(
                f"¡Hola {usuario.mention}! 👋\n"
                f"El equipo de soporte de **ExylioMC** te atenderá pronto.\n\n"
                "**Por favor describe tu problema:**\n"
                "```• ¿Qué ocurrió exactamente?\n• ¿Cuándo comenzó el problema?\n• ¿Tienes capturas o pruebas?```"
            ),
            color=MINECRAFT_BLUE
        )
        
        embed.set_thumbnail(url="https://cdn.discordapp.com/attachments/1385474084451782756/1385486499176255559/ChatGPT_Image_28_abr_2025_02_18_16.png?ex=68563e5a&is=6854ecda&hm=cf3cbb0dee99ffe8388c36e833a51f61da049dbdcc1640725d38f635dc3cfbc2&")
        embed.add_field(name="📝 Estado", value="🟡 Pendiente", inline=True)
        embed.add_field(name="👤 Creado por", value=usuario.mention, inline=True)
        
        embed.add_field(
            name="👑 STAFF DE ExylioMC",
            value=(
                "• Helper: @『𝐄𝐱𝐲𝐥𝐢𝐨𝐌𝐜┆Helper』\n"
                "• Mod Jr: @『𝐄𝐱𝐲𝐥𝐢𝐨𝐌𝐜┆Mod-Jr』\n"
                "• Moderador: @『𝐄𝐱𝐲𝐥𝐢𝐨𝐌𝐜┆Moderador』\n"
                "• Admin Jr: @『𝐄𝐱𝐲𝐥𝐢𝐨𝐌𝐜┆Admin-Jr』\n"
                "• Co-Admin: @『𝐄𝐱𝐲𝐥𝐢𝐨𝐌𝐜┆Co-Admin』\n"
                "• Administrador: @『𝐄𝐱𝐲𝐥𝐢𝐨𝐌𝐜┆Administrador』"
           ),
            inline=False
        )
        
        # Enviar mensaje principal con botones
        view = TicketView()
        await canal_ticket.send(embed=embed, view=view)
        
        # Enviar menú de estados en otro mensaje
        estado_view = EstadoView()
        await canal_ticket.send(view=estado_view)
        
        # Mensaje de confirmación al usuario
        try:
            user_embed = discord.Embed(
                title="✅ Ticket creado con éxito",
                description=f"Tu ticket ha sido creado en {canal_ticket.mention}",
                color=MINECRAFT_GREEN
            )
            user_embed.add_field(
                name="Próximos pasos",
                value="Por favor dirígete al canal de tu ticket y describe tu problema en detalle.",
                inline=False
            )
            user_embed.set_thumbnail(url="https://cdn.discordapp.com/attachments/1385474084451782756/1385486499176255559/ChatGPT_Image_28_abr_2025_02_18_16.png?ex=68563e5a&is=6854ecda&hm=cf3cbb0dee99ffe8388c36e833a51f61da049dbdcc1640725d38f635dc3cfbc2&")
            await usuario.send(embed=user_embed)
        except:
            pass
        
        # Guardar en base de datos
        ticket_data = {
            "canal_id": str(canal_ticket.id),
            "usuario_id": str(usuario.id),
            "estado": "🟡 Pendiente",
            "fecha_creacion": datetime.datetime.now().isoformat(),
            "fecha_archivado": None,
            "guild_id": str(guild.id)
        }
        save_ticket(ticket_data)
        
        # Registrar log de manera segura
        try:
            if CANAL_LOGS_OBJ:
                await registrar_log(guild, f"🎫 Ticket creado por {usuario.mention} en {canal_ticket.mention}")
        except:
            print("⚠️ No se pudo registrar el log del nuevo ticket")
    except Exception as e:
        print(f"Error al enviar mensaje inicial: {e}")
        try:
            if CANAL_LOGS_OBJ:
                await registrar_log(guild, f"❌ Error al inicializar ticket {canal_ticket.name}: {e}")
        except:
            print("⚠️ No se pudo registrar el error en el log")

async def archivar_ticket_handler(interaction: discord.Interaction):
    if "-ticket-" not in interaction.channel.name:
        await interaction.response.send_message("❌ Este comando solo puede usarse en un ticket.", ephemeral=True)
        return
    
    canal_id = str(interaction.channel.id)
    ticket = get_ticket(canal_id)
    if not ticket:
        await interaction.response.send_message("❌ No se encontró información de este ticket.", ephemeral=True)
        return
    
    # Verificar permisos: creador o staff
    es_creador = ticket["usuario_id"] == str(interaction.user.id)
    es_staff = any(role.name in ROLES_STAFF for role in interaction.user.roles)
    
    if not (es_creador or es_staff):
        await interaction.response.send_message("❌ Solo el creador del ticket o el staff pueden archivarlo.", ephemeral=True)
        return
    
    duracion = discord.utils.utcnow() - interaction.channel.created_at
    
    embed = discord.Embed(
        title="🔒 ¿Archivar ticket?",
        description="¿Estás seguro de que deseas archivar este ticket?\n\n*El creador perderá acceso, pero el ticket quedará visible para el staff.*",
        color=MINECRAFT_RED
    )
    embed.set_thumbnail(url="https://cdn.discordapp.com/attachments/1385474084451782756/1385486499176255559/ChatGPT_Image_28_abr_2025_02_18_16.png?ex=68563e5a&is=6854ecda&hm=cf3cbb0dee99ffe8388c36e833a51f61da049dbdcc1640725d38f635dc3cfbc2&")
    
    embed.add_field(
        name="Detalles del ticket",
        value=f"Creado por: <@{ticket['usuario_id']}>\nDuración: {duracion}",
        inline=False
    )
    
    view = ConfirmArchiveView()
    await interaction.response.send_message(embed=embed, view=view)

async def archivar_ticket_confirmado(interaction: discord.Interaction):
    canal_id = str(interaction.channel.id)
    ticket = get_ticket(canal_id)
    if not ticket:
        await interaction.response.send_message("❌ No se encontró información de este ticket.", ephemeral=True)
        return
    
    # Actualizar estado y fecha de archivado
    ticket["estado"] = "🔒 Archivado"
    ticket["fecha_archivado"] = datetime.datetime.now().isoformat()
    save_ticket(ticket)
    
    # Obtener el usuario creador
    guild = interaction.guild
    usuario_creador = guild.get_member(int(ticket["usuario_id"]))
    
    # Quitar permisos al creador
    if usuario_creador:
        await interaction.channel.set_permissions(usuario_creador, overwrite=None)
    
    # Registrar log de manera segura
    try:
        await registrar_log(guild, f"🔒 Ticket {interaction.channel.name} archivado por {interaction.user.mention}")
    except:
        print("⚠️ No se pudo registrar el log de archivo")
    
    despedida_embed = discord.Embed(
        title="🔒 Ticket Archivado",
        description="Este ticket ha sido archivado. El staff puede reabrirlo o eliminarlo definitivamente.",
        color=MINECRAFT_PURPLE
    )
    despedida_embed.set_thumbnail(url="https://cdn.discordapp.com/attachments/1385474084451782756/1385486499176255559/ChatGPT_Image_28_abr_2025_02_18_16.png?ex=68563e5a&is=6854ecda&hm=cf3cbb0dee99ffe8388c36e833a51f61da049dbdcc1640725d38f635dc3cfbc2&")
    despedida_embed.add_field(
        name="Acciones disponibles",
        value="El staff puede usar los botones a continuación para reabrir o eliminar este ticket.",
        inline=False
    )
    
    # Enviar vista con botones de reabrir y eliminar
    view = AfterArchiveView()
    
    await interaction.response.edit_message(content="✅ Ticket archivado con éxito", embed=None, view=None)
    await interaction.channel.send(embed=despedida_embed, view=view)

async def reabrir_ticket_handler(interaction: discord.Interaction):
    canal_id = str(interaction.channel.id)
    ticket = get_ticket(canal_id)
    if not ticket:
        await interaction.response.send_message("❌ No se encontró información de este ticket.", ephemeral=True)
        return
    
    # Eliminar mensaje de ticket archivado
    try:
        async for message in interaction.channel.history(limit=20):
            if message.author == bot.user and message.embeds:
                if message.embeds[0].title and "🔒 Ticket Archivado" in message.embeds[0].title:
                    await message.delete()
                    break
    except Exception as e:
        print(f"⚠️ Error eliminando mensaje archivado: {e}")
    
    # Actualizar estado
    ticket["estado"] = "🟡 Pendiente"
    ticket["fecha_archivado"] = None
    save_ticket(ticket)
    
    # Obtener el usuario creador
    guild = interaction.guild
    usuario_creador = guild.get_member(int(ticket["usuario_id"]))
    
    # Dar permisos al creador
    if usuario_creador:
        await interaction.channel.set_permissions(
            usuario_creador, 
            read_messages=True, 
            send_messages=True
        )
    
    # Buscar y actualizar el embed principal
    async for message in interaction.channel.history(limit=10):
        if message.embeds and message.author == bot.user:
            original_embed = message.embeds[0]
            
            for i, field in enumerate(original_embed.fields):
                if field.name == "📝 Estado":
                    original_embed.set_field_at(i, name="📝 Estado", value="🟡 Pendiente", inline=True)
                    original_embed.color = MINECRAFT_BLUE
                    break
            
            await message.edit(embed=original_embed)
            break
    
    embed = discord.Embed(
        title="🔓 Ticket Reabierto",
        description=f"Este ticket ha sido reabierto por {interaction.user.mention}",
        color=MINECRAFT_GREEN
    )
    embed.set_thumbnail(url="https://cdn.discordapp.com/attachments/1385474084451782756/1385486499176255559/ChatGPT_Image_28_abr_2025_02_18_16.png?ex=68563e5a&is=6854ecda&hm=cf3cbb0dee99ffe8388c36e833a51f61da049dbdcc1640725d38f635dc3cfbc2&")
    embed.add_field(
        name="Acciones disponibles",
        value="El ticket está nuevamente activo. Puedes continuar la conversación.",
        inline=False
    )
    
    await interaction.response.send_message(embed=embed)
    
    # Notificar al usuario creador
    if usuario_creador and usuario_creador.id != interaction.user.id:
        try:
            user_embed = discord.Embed(
                title="🔓 Ticket Reabierto",
                description=f"Tu ticket en {interaction.channel.mention} ha sido reabierto",
                color=MINECRAFT_GREEN
            )
            await usuario_creador.send(embed=user_embed)
        except:
            pass
    
    # Registrar log de manera segura
    try:
        await registrar_log(guild, f"🔓 Ticket {interaction.channel.name} reabierto por {interaction.user.mention}")
    except:
        print("⚠️ No se pudo registrar el log de reapertura")

async def eliminar_ticket_handler(interaction: discord.Interaction):
    canal_id = str(interaction.channel.id)
    delete_ticket(canal_id)
    
    await interaction.response.send_message("🗑️ Eliminando ticket...")
    await asyncio.sleep(2)
    
    # Registrar log antes de eliminar
    try:
        await registrar_log(interaction.guild, f"🗑️ Ticket eliminado por {interaction.user.mention}")
    except:
        print("⚠️ No se pudo registrar el log de eliminación")
    
    await interaction.channel.delete(reason=f"Ticket eliminado por {interaction.user}")

async def transcript_handler(interaction: discord.Interaction):
    if "-ticket-" not in interaction.channel.name:
        await interaction.response.send_message("❌ Este comando solo puede usarse en un ticket.", ephemeral=True)
        return
    
    embed_espera = discord.Embed(
        title="📜 Generando Transcript...",
        description="Estamos recopilando todo el historial del chat. Esto puede tomar unos segundos.",
        color=MINECRAFT_GOLD
    )
    embed_espera.set_thumbnail(url="https://cdn.discordapp.com/attachments/1385474084451782756/1385486499176255559/ChatGPT_Image_28_abr_2025_02_18_16.png?ex=68563e5a&is=6854ecda&hm=cf3cbb0dee99ffe8388c36e833a51f61da049dbdcc1640725d38f635dc3cfbc2&")
    await interaction.response.send_message(embed=embed_espera, ephemeral=False)
    
    try:
        # Crear carpeta para adjuntos
        ticket_folder = os.path.join(ATTACHMENTS_BASE, str(interaction.channel.id))
        os.makedirs(ticket_folder, exist_ok=True)
        
        transcript_lines = []
        total_messages = 0
        
        # Procesar mensajes en chunks para ahorrar memoria
        async for chunk in interaction.channel.history(limit=None, oldest_first=True).chunk(100):
            for message in chunk:
                total_messages += 1
                safe_content = html.escape(message.clean_content)
                
                attachments = ""
                if message.attachments:
                    # Descargar cada adjunto
                    for i, attachment in enumerate(message.attachments):
                        try:
                            # Obtener los datos del archivo
                            data = await attachment.read()
                            
                            # Comprimir los datos
                            compressed_data = zlib.compress(data)
                            
                            # Guardar en disco
                            file_path = os.path.join(ticket_folder, attachment.filename)
                            # Si el archivo ya existe, agregar un sufijo
                            if os.path.exists(file_path):
                                base, ext = os.path.splitext(attachment.filename)
                                file_path = os.path.join(ticket_folder, f"{base}_{i}{ext}")
                            with open(file_path, "wb") as f:
                                f.write(compressed_data)
                            # Registrar en el transcript
                            attachments += f" [Archivo guardado: {os.path.basename(file_path)}]"
                            
                            # Enviar al canal de archivos si está configurado
                            if CANAL_ARCHIVOS_OBJ:
                                await CANAL_ARCHIVOS_OBJ.send(
                                    content=f"**Archivo de ticket:** {interaction.channel.mention}",
                                    file=await attachment.to_file()
                                )
                        except Exception as e:
                            print(f"Error al descargar adjunto: {e}")
                            attachments += f" [Error al descargar: {attachment.filename}]"
                
                timestamp = message.created_at.strftime('%Y-%m-%d %H:%M:%S')
                transcript_lines.append(
                    f"[{timestamp}] {message.author.display_name}: {safe_content}{attachments}"
                )
            
            # Liberar memoria después de procesar cada chunk
            del chunk
        
        transcript_content = "\n".join(transcript_lines)
        
        # Crear archivo de transcript
        transcript_bytes = transcript_content.encode('utf-8')
        file_name = f"transcript-{interaction.channel.name}.txt"
        
        embed = discord.Embed(
            title="📜 Transcript Generado",
            description="Se ha creado un registro completo de este ticket.",
            color=MINECRAFT_GREEN
        )
        embed.set_thumbnail(url="https://cdn.discordapp.com/attachments/1385474084451782756/1385486499176255559/ChatGPT_Image_28_abr_2025_02_18_16.png?ex=68563e5a&is=6854ecda&hm=cf3cbb0dee99ffe8388c36e833a51f61da049dbdcc1640725d38f635dc3cfbc2&")
        embed.add_field(
            name="Detalles",
            value=f"• Mensajes registrados: {total_messages}\n• Canal: {interaction.channel.mention}",
            inline=False
        )
        
        # Enviar transcript al canal de logs si existe
        try:
            if CANAL_LOGS_OBJ:
                log_embed = discord.Embed(
                    title="📜 Nuevo Transcript Generado",
                    description=f"Ticket: {interaction.channel.mention}\nGenerado por: {interaction.user.mention}",
                    color=MINECRAFT_BLUE
                )
                log_embed.set_thumbnail(url="https://cdn.discordapp.com/attachments/1385474084451782756/1385486499176255559/ChatGPT_Image_28_abr_2025_02_18_16.png?ex=68563e5a&is=6854ecda&hm=cf3cbb0dee99ffe8388c36e833a51f61da049dbdcc1640725d38f635dc3cfbc2&")
                await CANAL_LOGS_OBJ.send(
                    embed=log_embed, 
                    file=discord.File(io.BytesIO(transcript_bytes), filename=file_name)
                )            
        except:
            print("⚠️ No se pudo enviar transcript al canal de logs")
        
        await interaction.edit_original_response(
            embed=embed,
            attachments=[discord.File(io.BytesIO(transcript_bytes), filename=file_name)]
        )
        
        # Registrar log de manera segura
        try:
            await registrar_log(interaction.guild, f"📜 Transcript generado para {interaction.channel.mention} por {interaction.user.mention}")
        except:
            print("⚠️ No se pudo registrar el log del transcript")
    except Exception as e:
        error_embed = discord.Embed(
            title="❌ Error al generar transcript",
            description=f"Ocurrió un error al generar el registro: {str(e)}",
            color=MINECRAFT_RED
        )
        error_embed.set_thumbnail(url="https://cdn.discordapp.com/attachments/1385474084451782756/1385486499176255559/ChatGPT_Image_28_abr_2025_02_18_16.png?ex=68563e5a&is=6854ecda&hm=cf3cbb0dee99ffe8388c36e833a51f61da049dbdcc1640725d38f635dc3cfbc2&")
        await interaction.edit_original_response(embed=error_embed)
        print(f"Error generando transcript: {e}")
        try:
            await registrar_log(interaction.guild, f"❌ Error generando transcript para {interaction.channel.mention}: {e}")
        except:
            print("⚠️ No se pudo registrar el error del transcript")

@bot.tree.command(name="tickets", description="🎫 Muestra los tickets activos")
async def listar_tickets(interaction: discord.Interaction):
    tickets_activos = get_active_tickets(interaction.guild.id)
    
    if not tickets_activos:
        embed = discord.Embed(
            description="ℹ️ No hay tickets activos en este momento",
            color=MINECRAFT_BLUE
        )
        embed.set_thumbnail(url="https://cdn.discordapp.com/attachments/1385474084451782756/1385486499176255559/ChatGPT_Image_28_abr_2025_02_18_16.png?ex=68563e5a&is=6854ecda&hm=cf3cbb0dee99ffe8388c36e833a51f61da049dbdcc1640725d38f635dc3cfbc2&")
        await interaction.response.send_message(embed=embed, ephemeral=True)
        return
    
    embed = discord.Embed(
        title="🎫 Tickets Activos",
        description="Lista de todos los tickets abiertos:",
        color=MINECRAFT_GOLD
    )
    embed.set_thumbnail(url="https://cdn.discordapp.com/attachments/1385474084451782756/1385486499176255559/ChatGPT_Image_28_abr_2025_02_18_16.png?ex=68563e5a&is=6854ecda&hm=cf3cbb0dee99ffe8388c36e833a51f61da049dbdcc1640725d38f635dc3cfbc2&")
    
    for ticket in tickets_activos:
        canal = interaction.guild.get_channel(int(ticket["canal_id"]))
        if canal:
            usuario = interaction.guild.get_member(int(ticket["usuario_id"]))
            usuario_mention = usuario.mention if usuario else f"<@{ticket['usuario_id']}>"
            
            embed.add_field(
                name=f"{ticket['estado']} - {canal.name}",
                value=f"Creado por: {usuario_mention}\n{canal.mention} | Creado: <t:{int(canal.created_at.timestamp())}:R>",
                inline=False
            )
    
    await interaction.response.send_message(embed=embed, ephemeral=True)

# Comando de estadísticas
@bot.tree.command(name="estadisticas_tickets", description="📊 Muestra estadísticas de los tickets")
async def estadisticas_tickets(interaction: discord.Interaction):
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    
    # Contar tickets activos
    cursor.execute("SELECT COUNT(*) FROM tickets WHERE fecha_archivado IS NULL AND guild_id = ?", (str(interaction.guild.id),))
    activos = cursor.fetchone()[0]
    
    # Contar tickets archivados
    cursor.execute("SELECT COUNT(*) FROM tickets WHERE fecha_archivado IS NOT NULL AND guild_id = ?", (str(interaction.guild.id),))
    archivados = cursor.fetchone()[0]
    
    # Total histórico
    total = activos + archivados
    
    conn.close()
    
    embed = discord.Embed(
        title="📊 ESTADÍSTICAS DE TICKETS",
        color=MINECRAFT_PURPLE
    )
    embed.set_thumbnail(url="https://cdn.discordapp.com/attachments/1385474084451782756/1385486499176255559/ChatGPT_Image_28_abr_2025_02_18_16.png?ex=68563e5a&is=6854ecda&hm=cf3cbb0dee99ffe8388c36e833a51f61da049dbdcc1640725d38f635dc3cfbc2&")
    
    embed.add_field(
        name="🎫 Tickets Activos", 
        value=f"```{activos}```", 
        inline=True
    )
    embed.add_field(
        name="🔒 Tickets Archivados", 
        value=f"```{archivados}```", 
        inline=True
    )
    embed.add_field(
        name="📜 Total Histórico", 
        value=f"```{total}```", 
        inline=True
    )
    
    # Calcular tiempo promedio de resolución
    if archivados > 0:
        conn = sqlite3.connect(DB_FILE)
        cursor = conn.cursor()
        cursor.execute("""
            SELECT AVG(
                (JULIANDAY(fecha_archivado) - JULIANDAY(fecha_creacion)) * 24
            FROM tickets 
            WHERE fecha_archivado IS NOT NULL AND guild_id = ?
        """, (str(interaction.guild.id),))
        promedio_horas = cursor.fetchone()[0]
        conn.close()
        
        if promedio_horas:
            horas = int(promedio_horas)
            minutos = int((promedio_horas - horas) * 60)
            embed.add_field(
                name="⏱️ Tiempo Promedio", 
                value=f"```{horas}h {minutos}m```", 
                inline=False
            )
    
    await interaction.response.send_message(embed=embed)

# Comando para buscar tickets
@bot.tree.command(name="buscar_tickets", description="🔍 Busca tickets por usuario o estado")
@app_commands.describe(usuario="Usuario a buscar", estado="Estado del ticket")
async def buscar_tickets(
    interaction: discord.Interaction,
    usuario: discord.Member = None,
    estado: str = None
):
    # Construir consulta SQL
    query = "SELECT * FROM tickets WHERE guild_id = ?"
    params = [str(interaction.guild.id)]
    
    if usuario:
        query += " AND usuario_id = ?"
        params.append(str(usuario.id))
    
    if estado:
        query += " AND estado = ?"
        params.append(estado)
    
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    cursor.execute(query, tuple(params))
    resultados = cursor.fetchall()
    conn.close()
    
    embed = discord.Embed(
        title="🔍 RESULTADOS DE BÚSQUEDA",
        color=MINECRAFT_BLUE
    )
    embed.set_thumbnail(url="https://cdn.discordapp.com/attachments/1385474084451782756/1385486499176255559/ChatGPT_Image_28_abr_2025_02_18_16.png?ex=68563e5a&is=6854ecda&hm=cf3cbb0dee99ffe8388c36e833a51f61da049dbdcc1640725d38f635dc3cfbc2&")
    
    if resultados:
        output = []
        for i, ticket in enumerate(resultados[:8]):  # Limitar a 8 resultados
            canal = interaction.guild.get_channel(int(ticket[0]))
            if canal:
                user = interaction.guild.get_member(int(ticket[1]))
                user_name = user.display_name if user else f"ID:{ticket[1]}"
                output.append(f"{ticket[2]} - {canal.mention} - {user_name}")
        
        embed.description = "\n".join(output)
        if len(resultados) > 8:
            embed.set_footer(text=f"Mostrando 8 de {len(resultados)} resultados")
    else:
        embed.description = "❌ No se encontraron tickets que coincidan con tu búsqueda"
        embed.set_footer(text="Prueba con diferentes filtros")
    
    await interaction.response.send_message(embed=embed, ephemeral=True)

@bot.tree.command(name="agregar", description="👤 Agrega un usuario al ticket actual")
@app_commands.describe(usuario="Usuario a agregar al ticket")
@app_commands.default_permissions(manage_channels=True)
async def agregar(interaction: discord.Interaction, usuario: discord.Member):
    if "-ticket-" not in interaction.channel.name:
        await interaction.response.send_message("❌ Este comando solo puede usarse en un ticket.", ephemeral=True)
        return
    
    if usuario.bot:
        await interaction.response.send_message("❌ No puedes agregar bots a los tickets.", ephemeral=True)
        return
    
    await interaction.channel.set_permissions(usuario, read_messages=True, send_messages=True)
    
    embed = discord.Embed(
        description=f"✅ {usuario.mention} ha sido añadido al ticket!",
        color=MINECRAFT_GREEN
    )
    embed.set_thumbnail(url="https://cdn.discordapp.com/attachments/1385474084451782756/1385486499176255559/ChatGPT_Image_28_abr_2025_02_18_16.png?ex=68563e5a&is=6854ecda&hm=cf3cbb0dee99ffe8388c36e833a51f61da049dbdcc1640725d38f635dc3cfbc2&")
    await interaction.response.send_message(embed=embed)
    
    # Registrar log de manera segura
    try:
        await registrar_log(interaction.guild, f"👤 {usuario.mention} añadido al ticket por {interaction.user.mention} en {interaction.channel.mention}")
    except:
        print("⚠️ No se pudo registrar el log de adición")

@bot.tree.command(name="remover", description="🚫 Remueve un usuario del ticket actual")
@app_commands.describe(usuario="Usuario a remover del ticket")
@app_commands.default_permissions(manage_channels=True)
async def remover(interaction: discord.Interaction, usuario: discord.Member):
    if "-ticket-" not in interaction.channel.name:
        await interaction.response.send_message("❌ Este comando solo puede usarse en un ticket.", ephemeral=True)
        return
    
    # Obtener creador del ticket desde los datos
    canal_id = str(interaction.channel.id)
    ticket = get_ticket(canal_id)
    if not ticket:
        await interaction.response.send_message("❌ No se encontró información de este ticket.", ephemeral=True)
        return
    
    # Verificar si es el creador
    if ticket["usuario_id"] == str(usuario.id):
        await interaction.response.send_message("❌ No puedes remover al creador del ticket. Archiva el ticket en su lugar.", ephemeral=True)
        return
    
    await interaction.channel.set_permissions(usuario, overwrite=None)
    
    embed = discord.Embed(
        description=f"✅ {usuario.mention} ha sido removido del ticket!",
        color=MINECRAFT_GREEN
    )
    embed.set_thumbnail(url="https://cdn.discordapp.com/attachments/1385474084451782756/1385486499176255559/ChatGPT_Image_28_abr_2025_02_18_16.png?ex=68563e5a&is=6854ecda&hm=cf3cbb0dee99ffe8388c36e833a51f61da049dbdcc1640725d38f635dc3cfbc2&")
    await interaction.response.send_message(embed=embed)
    
    # Registrar log de manera segura
    try:
        await registrar_log(interaction.guild, f"👤 {usuario.mention} removido del ticket por {interaction.user.mention} en {interaction.channel.mention}")
    except:
        print("⚠️ No se pudo registrar el log de remoción")

async def registrar_log(guild, accion):
    global CANAL_LOGS_OBJ

    if not CANAL_LOGS_OBJ:
        return
    
    try:
        # Verificar si el canal aún existe
        canal = await guild.fetch_channel(CANAL_LOGS_OBJ.id)
    except discord.NotFound:
        print("❌ Canal de logs no encontrado. Por favor configura uno nuevo.")
        CANAL_LOGS_OBJ = None
        return
    except discord.Forbidden:
        print("⚠️ Sin permisos para acceder al canal de logs")
        return
    except Exception as e:
        print(f"⚠️ Error verificando canal de logs: {e}")
        return
    
    # Crear embed del log
    embed = discord.Embed(
        title="📝 Registro del Sistema de Tickets",
        description=accion,
        color=MINECRAFT_PURPLE,
        timestamp=datetime.datetime.now()
    )
    
    if "añadido" in accion:
        embed.color = MINECRAFT_GREEN
        embed.set_thumbnail(url="https://cdn.discordapp.com/attachments/1385474084451782756/1385486499176255559/ChatGPT_Image_28_abr_2025_02_18_16.png?ex=68563e5a&is=6854ecda&hm=cf3cbb0dee99ffe8388c36e833a51f61da049dbdcc1640725d38f635dc3cfbc2&")
    elif "removido" in accion:
        embed.color = MINECRAFT_RED
        embed.set_thumbnail(url="https://cdn.discordapp.com/attachments/1385474084451782756/1385486499176255559/ChatGPT_Image_28_abr_2025_02_18_16.png?ex=68563e5a&is=6854ecda&hm=cf3cbb0dee99ffe8388c36e833a51f61da049dbdcc1640725d38f635dc3cfbc2&")
    elif "creado" in accion:
        embed.color = MINECRAFT_BLUE
        embed.set_thumbnail(url="https://cdn.discordapp.com/attachments/1385474084451782756/1385486499176255559/ChatGPT_Image_28_abr_2025_02_18_16.png?ex=68563e5a&is=6854ecda&hm=cf3cbb0dee99ffe8388c36e833a51f61da049dbdcc1640725d38f635dc3cfbc2&")
    elif "archivado" in accion:
        embed.color = MINECRAFT_GOLD
        embed.set_thumbnail(url="https://cdn.discordapp.com/attachments/1385474084451782756/1385486499176255559/ChatGPT_Image_28_abr_2025_02_18_16.png?ex=68563e5a&is=6854ecda&hm=cf3cbb0dee99ffe8388c36e833a51f61da049dbdcc1640725d38f635dc3cfbc2&")
    elif "reabierto" in accion:
        embed.color = MINECRAFT_GREEN
        embed.set_thumbnail(url="https://cdn.discordapp.com/attachments/1385474084451782756/1385486499176255559/ChatGPT_Image_28_abr_2025_02_18_16.png?ex=68563e5a&is=6854ecda&hm=cf3cbb0dee99ffe8388c36e833a51f61da049dbdcc1640725d38f635dc3cfbc2&")
    elif "Transcript" in accion:
        embed.color = MINECRAFT_PURPLE
        embed.set_thumbnail(url="https://cdn.discordapp.com/attachments/1385474084451782756/1385486499176255559/ChatGPT_Image_28_abr_2025_02_18_16.png?ex=68563e5a&is=6854ecda&hm=cf3cbb0dee99ffe8388c36e833a51f61da049dbdcc1640725d38f635dc3cfbc2&")
    elif "eliminado" in accion:
        embed.color = MINECRAFT_RED
        embed.set_thumbnail(url="https://cdn.discordapp.com/attachments/1385474084451782756/1385486499176255559/ChatGPT_Image_28_abr_2025_02_18_16.png?ex=68563e5a&is=6854ecda&hm=cf3cbb0dee99ffe8388c36e833a51f61da049dbdcc1640725d38f635dc3cfbc2&")
            
    embed.set_footer(text=f"ID del servidor: {guild.id}")
    
    try:
        await CANAL_LOGS_OBJ.send(embed=embed)
    except discord.NotFound:
        print("❌ No se pudo enviar log: Canal eliminado")
        CANAL_LOGS_OBJ = None
    except discord.Forbidden:
        print("⚠️ Sin permisos para enviar mensajes al canal de logs")
    except Exception as e:
        print(f"⚠️ Error enviando log: {e}")

@bot.tree.command(name="ayuda", description="❓ Muestra la ayuda del sistema de tickets")
async def ayuda(interaction: discord.Interaction):
    embed = discord.Embed(
        title="🛠️ Ayuda del Sistema de Tickets",
        description="Recursos disponibles para el sistema de tickets de ExylioMC",
        color=MINECRAFT_BLUE
    )
    embed.set_thumbnail(url="https://cdn.discordapp.com/attachments/1385474084451782756/1385486499176255559/ChatGPT_Image_28_abr_2025_02_18_16.png?ex=68563e5a&is=6854ecda&hm=cf3cbb0dee99ffe8388c36e833a51f61da049dbdcc1640725d38f635dc3cfbc2&")
    
    embed.add_field(
        name="Creación de Tickets",
        value="Usa el botón en el panel de tickets o el comando `/ticket` para crear un nuevo ticket de soporte",
        inline=False
    )
    
    embed.add_field(
        name="Acciones en Tickets",
        value=(
            "Usa los botones en el ticket para:\n\n"
            "🔒 **Archivar Ticket** - Cierra y archiva este ticket (solo staff/creador)\n"
            "📜 **Generar Transcript** - Crea un registro completo del chat\n"
            "⬇️ **Cambiar Estado** - Actualiza el estado del ticket (solo staff)\n"
            "🔓 **Reabrir Ticket** - Vuelve a abrir un ticket archivado (solo staff)\n"
            "🗑️ **Eliminar Ticket** - Borra definitivamente el ticket (solo staff)"
        ),
        inline=False
    )
    
    embed.add_field(
        name="Comandos para Staff",
        value=(
            "`/tickets` - Lista todos los tickets activos\n"
            "`/estadisticas_tickets` - Muestra estadísticas de tickets\n"
            "`/buscar_tickets` - Busca tickets por usuario o estado\n"
            "`/establecer_canal_logs` - Establece el canal para logs\n"
            "`/establecer_canal_archivos` - Establece el canal para archivos\n"
            "`/configurar [imagen_url]` - Crea el panel de tickets\n"
            "`/agregar @usuario` - Añade un usuario al ticket actual\n"
            "`/remover @usuario` - Remueve un usuario del ticket actual\n"
            "`/staff_agregar @rol` - Agrega un rol al staff\n"
            "`/staff_remover @rol` - Remueve un rol del staff"
        ),
        inline=False
    )
    
    embed.add_field(
        name="ℹ️ Notas importantes",
        value=(
            "• Los archivos adjuntos se guardan localmente y en un canal dedicado\n"
            "• Solo puedes tener 1 ticket activo a la vez\n"
            "• Los archivos antiguos se limpian automáticamente cada 20 días"
        ),
        inline=False
    )
    
    embed.set_footer(text="Servidor Minecraft ExylioMC")
    await interaction.response.send_message(embed=embed)

@bot.tree.error
async def on_app_command_error(interaction: discord.Interaction, error):
    if isinstance(error, app_commands.MissingPermissions):
        await interaction.response.send_message("❌ No tienes permisos para ejecutar este comando.", ephemeral=True)
    elif isinstance(error, app_commands.MissingRole):
        await interaction.response.send_message("❌ No tienes el rol requerido para este comando.", ephemeral=True)
    else:
        print(f"⚠ Error no manejado en comando de barra: {error}")
        await interaction.response.send_message("❌ Ocurrió un error al procesar el comando", ephemeral=True)
        if CANAL_LOGS_OBJ:
            try:
                error_embed = discord.Embed(
                    title="⚠ Error en comando de barra",
                    description=f"```{error}```",
                    color=MINECRAFT_RED
                )
                await CANAL_LOGS_OBJ.send(embed=error_embed)
            except:
                print("⚠️ No se pudo registrar el error en el canal de logs")
            
webserver.keep_alive()
TOKEN = os.getenv('DISCORD_TOKEN')
if TOKEN:
    bot.run(TOKEN)
else:
    print("❌ ERROR: No se encontró el token en .env")
    print("Crea un archivo .env con: DISCORD_TOKEN=tu_token")
