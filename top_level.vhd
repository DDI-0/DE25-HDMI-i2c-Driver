library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.vga_controller.all;

entity top_level is
    port (
        CLOCK2_50        : in    std_logic;
        CPU_RESET_n      : in    std_logic;
        HDMI_TX_CLK      : out   std_logic;
        HDMI_TX_HS       : out   std_logic;
        HDMI_TX_VS       : out   std_logic;
        HDMI_TX_DE       : out   std_logic;
        HDMI_TX_D        : out   std_logic_vector(23 downto 0);
        HDMI_TX_INT      : in    std_logic;
        FPGA_I2C_SCLK    : out   std_logic;
        FPGA_I2C_SDAT    : inout std_logic
    );
end entity top_level;

architecture structural of top_level is
    component reset_release is
        port ( ninit_done : out std_logic );
    end component reset_release;

    component pll is
        port (
            refclk   : in  std_logic := '0';
            rst      : in  std_logic := '0';
            outclk_0 : out std_logic
        );
    end component pll;

    component i2c_hdmi_config is
        port (
            clk          : in    std_logic;
            reset_n      : in    std_logic;
            i2c_sda      : inout std_logic;
            i2c_scl      : out   std_logic;
            hdmi_tx_int  : in    std_logic;
            config_done  : out   std_logic
        );
    end component;

    component vga_delay is
         generic (
             NUM_PIPES  : natural    := 1;
             COORD_BITS : natural    := 1;
             vga_res    : vga_timing := vga_res_1920x1080
         );
         port (
             clk             : in  std_logic;
             reset_n         : in  std_logic;
             h_sync_d        : out std_logic;
             v_sync_d        : out std_logic;
             point_valid_d   : out boolean;
             pixel_coord_d   : out coordinate;
             vga_blank_n_d   : out std_logic
         );
    end component vga_delay;

    signal ninit_done     : std_logic;
    signal pixel_clk      : std_logic;
    signal system_reset_n : std_logic;
    signal pll_rst        : std_logic;
    
    -- VGA Delayed Signals
    signal vga_hs_d       : std_logic;
    signal vga_vs_d       : std_logic;
    signal vga_blank_n_d  : std_logic;
    signal point_valid_d  : boolean;
    signal px_coord_d     : coordinate;
    
    -- Color Channels
    signal r_data         : std_logic_vector(7 downto 0);
    signal g_data         : std_logic_vector(7 downto 0);
    signal b_data         : std_logic_vector(7 downto 0);
    
    -- Square Dimensions
    constant SQ_SIZE      : integer := 200;
    constant CENTER_X     : integer := 1920 / 2;
    constant CENTER_Y     : integer := 1080 / 2;

begin

    u_reset_release : component reset_release 
        port map (ninit_done => ninit_done);

    system_reset_n <=  NOT ninit_done and CPU_RESET_n;
    pll_rst        <= NOT system_reset_n;

    u_pll : component pll
        port map (
            refclk   => CLOCK2_50,
            rst      => pll_rst,
            outclk_0 => pixel_clk
        );

    HDMI_TX_CLK <= pixel_clk;

    u_i2c_config : component i2c_hdmi_config
        port map (
            clk          => CLOCK2_50,
            reset_n      => system_reset_n,
            i2c_sda      => FPGA_I2C_SDAT,
            i2c_scl      => FPGA_I2C_SCLK,
            hdmi_tx_int  => HDMI_TX_INT,
            config_done  => open
        );

    u_vga_delay : component vga_delay
        generic map (
            NUM_PIPES  => 2,
            COORD_BITS => 12,
            vga_res    => vga_res_1920x1080
        )
        port map (
            clk             => pixel_clk,
            reset_n         => system_reset_n,
            h_sync_d        => vga_hs_d,
            v_sync_d        => vga_vs_d,
            point_valid_d   => point_valid_d,
            pixel_coord_d   => px_coord_d,
            vga_blank_n_d   => vga_blank_n_d
        );

    HDMI_TX_HS <= vga_hs_d;
    HDMI_TX_VS <= vga_vs_d;
    HDMI_TX_DE <= vga_blank_n_d; 

    process(pixel_clk)
    begin
        if rising_edge(pixel_clk) then
            -- Default Black
            r_data <= (others => '0');
            g_data <= (others => '0');
            b_data <= (others => '0');

            if point_valid_d then
                if (px_coord_d.x >= (CENTER_X - SQ_SIZE/2)) and (px_coord_d.x < (CENTER_X + SQ_SIZE/2)) and
                   (px_coord_d.y >= (CENTER_Y - SQ_SIZE/2)) and (px_coord_d.y < (CENTER_Y + SQ_SIZE/2)) then
                    
                    -- White Square
                    r_data <= x"FF";
                    g_data <= x"FF";
                    b_data <= x"FF";
                end if;
            end if;
        end if;
    end process;

    -- Map internal color signals to the output vector
    HDMI_TX_D(23 downto 16) <= r_data;
    HDMI_TX_D(15 downto 8)  <= g_data;
    HDMI_TX_D(7 downto 0)   <= b_data;
end architecture structural;