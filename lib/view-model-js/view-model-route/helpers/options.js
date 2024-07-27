module.exports = {
  formate: "A3",
  orientation: "potrait",
  border: "8mm",
  header: {
    height: "15mm",
    content:
      '<h4 style=" color: red;font-size:20;font-weight:800;text-align:center;">CUSTOMER INVOICE</h4>',
  },
  footer: {
    height: "20mm",
    contents: {
      first: " Cover Page",
      2: "Second Page",
      default:
        '<span style="color:#444;">{{page}}</span>/<span>{{pages}}</span>',
      last: "Last Page",
    },
  },
};
