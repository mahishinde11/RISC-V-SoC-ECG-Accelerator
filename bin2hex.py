import sys

def bin_to_hex(bin_file, hex_file):
    try:
        with open(bin_file, 'rb') as f:
            data = f.read()
        
        # Ensure data is 4-byte aligned
        padding = (4 - (len(data) % 4)) % 4
        data += b'\x00' * padding
        
        with open(hex_file, 'w') as f:
            # Process in 32-bit (4-byte) chunks
            for i in range(0, len(data), 4):
                chunk = data[i:i+4]
                # RISC-V is little-endian, but Verilog $readmemh usually 
                # expects words in big-endian order per line depending on how it's read.
                # Here we write the word so bit 31 of the value is the leftmost hex digit.
                val = int.from_bytes(chunk, byteorder='little')
                f.write(f"{val:08x}\n")
                
        print(f"Successfully converted {bin_file} to {hex_file}")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python bin2hex.py <input.bin> <output.hex>")
    else:
        bin_to_hex(sys.argv[1], sys.argv[2])
