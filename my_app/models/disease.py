# my_app/models/disease.py

from sqlalchemy import Column, Integer, String, Text
from database import Base


class Disease(Base):
    """Danh mục 38 lớp bệnh từ PlantVillage dataset."""
    __tablename__ = "diseases"

    id          = Column(Integer, primary_key=True, index=True, autoincrement=True)
    name_en     = Column(String(255), unique=True, nullable=False)  # PlantVillage label
    name_vi     = Column(String(255), nullable=False)               # Tên tiếng Việt
    plant       = Column(String(100), nullable=False)               # Cây trồng
    description = Column(Text, nullable=True)                       # Mô tả / triệu chứng


# ── Seed 38 class PlantVillage ────────────────────────────────────────────────
# Chạy 1 lần để nạp dữ liệu ban đầu (xem INTEGRATION_GUIDE.py)
DISEASE_SEED_DATA = [
    {"name_en": "Apple___Apple_scab",                                          "name_vi": "Ghẻ táo",                          "plant": "Táo"},
    {"name_en": "Apple___Black_rot",                                           "name_vi": "Thối đen táo",                     "plant": "Táo"},
    {"name_en": "Apple___Cedar_apple_rust",                                    "name_vi": "Gỉ sắt táo",                      "plant": "Táo"},
    {"name_en": "Apple___healthy",                                             "name_vi": "Táo khỏe mạnh",                   "plant": "Táo"},
    {"name_en": "Blueberry___healthy",                                         "name_vi": "Việt quất khỏe mạnh",             "plant": "Việt quất"},
    {"name_en": "Cherry_(including_sour)___Powdery_mildew",                   "name_vi": "Phấn trắng anh đào",              "plant": "Anh đào"},
    {"name_en": "Cherry_(including_sour)___healthy",                          "name_vi": "Anh đào khỏe mạnh",               "plant": "Anh đào"},
    {"name_en": "Corn_(maize)___Cercospora_leaf_spot Gray_leaf_spot",         "name_vi": "Đốm xám ngô",                     "plant": "Ngô"},
    {"name_en": "Corn_(maize)___Common_rust_",                                "name_vi": "Gỉ sắt ngô",                      "plant": "Ngô"},
    {"name_en": "Corn_(maize)___Northern_Leaf_Blight",                        "name_vi": "Cháy lá phương Bắc ngô",          "plant": "Ngô"},
    {"name_en": "Corn_(maize)___healthy",                                     "name_vi": "Ngô khỏe mạnh",                   "plant": "Ngô"},
    {"name_en": "Grape___Black_rot",                                           "name_vi": "Thối đen nho",                    "plant": "Nho"},
    {"name_en": "Grape___Esca_(Black_Measles)",                               "name_vi": "Bệnh Esca nho",                   "plant": "Nho"},
    {"name_en": "Grape___Leaf_blight_(Isariopsis_Leaf_Spot)",                 "name_vi": "Cháy lá nho",                     "plant": "Nho"},
    {"name_en": "Grape___healthy",                                             "name_vi": "Nho khỏe mạnh",                   "plant": "Nho"},
    {"name_en": "Orange___Haunglongbing_(Citrus_greening)",                   "name_vi": "Vàng lá greening cam",            "plant": "Cam"},
    {"name_en": "Peach___Bacterial_spot",                                      "name_vi": "Đốm vi khuẩn đào",               "plant": "Đào"},
    {"name_en": "Peach___healthy",                                             "name_vi": "Đào khỏe mạnh",                   "plant": "Đào"},
    {"name_en": "Pepper,_bell___Bacterial_spot",                              "name_vi": "Đốm vi khuẩn ớt chuông",          "plant": "Ớt chuông"},
    {"name_en": "Pepper,_bell___healthy",                                      "name_vi": "Ớt chuông khỏe mạnh",            "plant": "Ớt chuông"},
    {"name_en": "Potato___Early_blight",                                       "name_vi": "Cháy lá sớm khoai tây",          "plant": "Khoai tây"},
    {"name_en": "Potato___Late_blight",                                        "name_vi": "Mốc sương khoai tây",             "plant": "Khoai tây"},
    {"name_en": "Potato___healthy",                                            "name_vi": "Khoai tây khỏe mạnh",             "plant": "Khoai tây"},
    {"name_en": "Raspberry___healthy",                                         "name_vi": "Mâm xôi khỏe mạnh",              "plant": "Mâm xôi"},
    {"name_en": "Soybean___healthy",                                           "name_vi": "Đậu tương khỏe mạnh",            "plant": "Đậu tương"},
    {"name_en": "Squash___Powdery_mildew",                                     "name_vi": "Phấn trắng bí ngô",              "plant": "Bí ngô"},
    {"name_en": "Strawberry___Leaf_scorch",                                    "name_vi": "Cháy lá dâu tây",                "plant": "Dâu tây"},
    {"name_en": "Strawberry___healthy",                                        "name_vi": "Dâu tây khỏe mạnh",              "plant": "Dâu tây"},
    {"name_en": "Tomato___Bacterial_spot",                                     "name_vi": "Đốm vi khuẩn cà chua",           "plant": "Cà chua"},
    {"name_en": "Tomato___Early_blight",                                       "name_vi": "Cháy lá sớm cà chua",            "plant": "Cà chua"},
    {"name_en": "Tomato___Late_blight",                                        "name_vi": "Mốc sương cà chua",              "plant": "Cà chua"},
    {"name_en": "Tomato___Leaf_Mold",                                          "name_vi": "Mốc lá cà chua",                 "plant": "Cà chua"},
    {"name_en": "Tomato___Septoria_leaf_spot",                                 "name_vi": "Đốm lá Septoria cà chua",        "plant": "Cà chua"},
    {"name_en": "Tomato___Spider_mites Two-spotted_spider_mite",              "name_vi": "Nhện đỏ cà chua",                 "plant": "Cà chua"},
    {"name_en": "Tomato___Target_Spot",                                        "name_vi": "Đốm mục tiêu cà chua",           "plant": "Cà chua"},
    {"name_en": "Tomato___Tomato_Yellow_Leaf_Curl_Virus",                     "name_vi": "Virus cuốn lá vàng cà chua",     "plant": "Cà chua"},
    {"name_en": "Tomato___Tomato_mosaic_virus",                               "name_vi": "Virus khảm cà chua",              "plant": "Cà chua"},
    {"name_en": "Tomato___healthy",                                            "name_vi": "Cà chua khỏe mạnh",              "plant": "Cà chua"},
]