import qrcode
import io
import base64
from uuid import uuid4

class QRGenerator:
    """Genera códigos QR"""
    
    @staticmethod
    def generate_qr_code(data: str) -> str:
        """
        Genera código QR y lo retorna en base64
        
        Args:
            data: Datos a codificar en QR
        
        Returns:
            String en base64 de la imagen QR
        """
        qr = qrcode.QRCode(
            version=1,
            error_correction=qrcode.constants.ERROR_CORRECT_L,
            box_size=10,
            border=4,
        )
        qr.add_data(data)
        qr.make(fit=True)
        
        img = qr.make_image(fill_color="black", back_color="white")
        
        # Convertir imagen a base64
        buffered = io.BytesIO()
        img.save(buffered, format="PNG")
        img_str = base64.b64encode(buffered.getvalue()).decode()
        
        return img_str
    
    @staticmethod
    def generate_unique_qr_code() -> str:
        """Genera un código QR único"""
        return f"QR-{uuid4().hex[:12].upper()}"
